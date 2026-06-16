#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVPhotocardExtractor.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace {

constexpr double targetPhotocardRatio = 55.0 / 85.0;
constexpr double maxProcessingDimension = 1400.0;

struct EdgeLine {
    cv::Point2f point;
    cv::Point2f direction;
};

struct Candidate {
    std::vector<cv::Point2f> points;
    std::vector<cv::Point> contour;
    EdgeLine topLine;
    EdgeLine rightLine;
    EdgeLine bottomLine;
    EdgeLine leftLine;
    bool hasFittedLines = false;
    double fillRatio = 0;
    double score = 0;
};

std::vector<cv::Point2f> orderedClockwisePoints(std::vector<cv::Point2f> points);

double distanceBetween(const cv::Point2f &lhs, const cv::Point2f &rhs) {
    return std::hypot(lhs.x - rhs.x, lhs.y - rhs.y);
}

double cross(const cv::Point2f &lhs, const cv::Point2f &rhs) {
    return lhs.x * rhs.y - lhs.y * rhs.x;
}

double pointToLineDistance(
    const cv::Point2f &point,
    const cv::Point2f &lineStart,
    const cv::Point2f &lineEnd
) {
    cv::Point2f line = lineEnd - lineStart;
    double length = std::max(distanceBetween(lineStart, lineEnd), 1.0);
    return std::abs(cross(point - lineStart, line)) / length;
}

double projectionRatio(
    const cv::Point2f &point,
    const cv::Point2f &lineStart,
    const cv::Point2f &lineEnd
) {
    cv::Point2f line = lineEnd - lineStart;
    double lengthSquared = std::max(line.dot(line), 1.0f);
    return (point - lineStart).dot(line) / lengthSquared;
}

bool lineIntersection(
    const EdgeLine &first,
    const EdgeLine &second,
    cv::Point2f &intersection
) {
    double denominator = cross(first.direction, second.direction);
    if (std::abs(denominator) < 0.0001) {
        return false;
    }

    cv::Point2f delta = second.point - first.point;
    double t = cross(delta, second.direction) / denominator;
    intersection = first.point + first.direction * static_cast<float>(t);
    return std::isfinite(intersection.x) && std::isfinite(intersection.y);
}

bool fitEdgeLine(
    const std::vector<cv::Point> &contour,
    const cv::Point2f &lineStart,
    const cv::Point2f &lineEnd,
    EdgeLine &edgeLine
) {
    double sideLength = distanceBetween(lineStart, lineEnd);
    double maxDistance = std::clamp(sideLength * 0.035, 6.0, 26.0);

    std::vector<cv::Point2f> sidePoints;
    sidePoints.reserve(contour.size());
    for (const auto &point : contour) {
        cv::Point2f point2f(static_cast<float>(point.x), static_cast<float>(point.y));
        double t = projectionRatio(point2f, lineStart, lineEnd);
        if (t < 0.08 || t > 0.92) {
            continue;
        }

        if (pointToLineDistance(point2f, lineStart, lineEnd) <= maxDistance) {
            sidePoints.push_back(point2f);
        }
    }

    if (sidePoints.size() < 8) {
        return false;
    }

    cv::Vec4f fitted;
    cv::fitLine(sidePoints, fitted, cv::DIST_L2, 0, 0.01, 0.01);
    edgeLine.direction = cv::Point2f(fitted[0], fitted[1]);
    edgeLine.point = cv::Point2f(fitted[2], fitted[3]);
    return true;
}

bool isValidQuadrilateral(
    const std::vector<cv::Point2f> &points,
    const cv::Size &imageSize
) {
    if (points.size() != 4) {
        return false;
    }

    std::vector<cv::Point2f> ordered = orderedClockwisePoints(points);
    double area = std::abs(cv::contourArea(ordered));
    double imageArea = static_cast<double>(imageSize.width) * static_cast<double>(imageSize.height);
    if (area < imageArea * 0.06 || area > imageArea * 1.05) {
        return false;
    }

    for (const auto &point : ordered) {
        if (!std::isfinite(point.x) || !std::isfinite(point.y)) {
            return false;
        }

        if (point.x < -imageSize.width * 0.04
            || point.y < -imageSize.height * 0.04
            || point.x > imageSize.width * 1.04
            || point.y > imageSize.height * 1.04) {
            return false;
        }
    }

    double topWidth = distanceBetween(ordered[0], ordered[1]);
    double bottomWidth = distanceBetween(ordered[3], ordered[2]);
    double leftHeight = distanceBetween(ordered[0], ordered[3]);
    double rightHeight = distanceBetween(ordered[1], ordered[2]);
    double averageWidth = (topWidth + bottomWidth) / 2.0;
    double averageHeight = (leftHeight + rightHeight) / 2.0;
    double ratio = std::min(averageWidth, averageHeight) / std::max(std::max(averageWidth, averageHeight), 1.0);

    return ratio >= 0.50 && ratio <= 0.78;
}

std::vector<cv::Point2f> orderedClockwisePoints(std::vector<cv::Point2f> points) {
    std::vector<cv::Point2f> ordered(4);

    auto minSum = std::min_element(points.begin(), points.end(), [](const auto &lhs, const auto &rhs) {
        return lhs.x + lhs.y < rhs.x + rhs.y;
    });
    auto maxSum = std::max_element(points.begin(), points.end(), [](const auto &lhs, const auto &rhs) {
        return lhs.x + lhs.y < rhs.x + rhs.y;
    });
    auto minDiff = std::min_element(points.begin(), points.end(), [](const auto &lhs, const auto &rhs) {
        return lhs.y - lhs.x < rhs.y - rhs.x;
    });
    auto maxDiff = std::max_element(points.begin(), points.end(), [](const auto &lhs, const auto &rhs) {
        return lhs.y - lhs.x < rhs.y - rhs.x;
    });

    ordered[0] = *minSum;
    ordered[1] = *minDiff;
    ordered[2] = *maxSum;
    ordered[3] = *maxDiff;
    return ordered;
}

bool refineCornersFromFittedEdges(
    const std::vector<cv::Point> &contour,
    const std::vector<cv::Point2f> &initialPoints,
    const cv::Size &imageSize,
    std::vector<cv::Point2f> &refinedPoints,
    EdgeLine *outTopLine = nullptr,
    EdgeLine *outRightLine = nullptr,
    EdgeLine *outBottomLine = nullptr,
    EdgeLine *outLeftLine = nullptr
) {
    auto ordered = orderedClockwisePoints(initialPoints);

    EdgeLine topLine;
    EdgeLine rightLine;
    EdgeLine bottomLine;
    EdgeLine leftLine;

    if (!fitEdgeLine(contour, ordered[0], ordered[1], topLine)
        || !fitEdgeLine(contour, ordered[1], ordered[2], rightLine)
        || !fitEdgeLine(contour, ordered[3], ordered[2], bottomLine)
        || !fitEdgeLine(contour, ordered[0], ordered[3], leftLine)) {
        return false;
    }

    std::vector<cv::Point2f> intersections(4);
    if (!lineIntersection(topLine, leftLine, intersections[0])
        || !lineIntersection(topLine, rightLine, intersections[1])
        || !lineIntersection(bottomLine, rightLine, intersections[2])
        || !lineIntersection(bottomLine, leftLine, intersections[3])) {
        return false;
    }

    refinedPoints = orderedClockwisePoints(intersections);
    if (!isValidQuadrilateral(refinedPoints, imageSize)) {
        return false;
    }

    if (outTopLine) { *outTopLine = topLine; }
    if (outRightLine) { *outRightLine = rightLine; }
    if (outBottomLine) { *outBottomLine = bottomLine; }
    if (outLeftLine) { *outLeftLine = leftLine; }
    return true;
}

double candidateScore(
    const std::vector<cv::Point2f> &points,
    double supportArea,
    const cv::Size &imageSize
) {
    auto ordered = orderedClockwisePoints(points);
    double topWidth = distanceBetween(ordered[0], ordered[1]);
    double bottomWidth = distanceBetween(ordered[3], ordered[2]);
    double leftHeight = distanceBetween(ordered[0], ordered[3]);
    double rightHeight = distanceBetween(ordered[1], ordered[2]);

    double averageWidth = (topWidth + bottomWidth) / 2.0;
    double averageHeight = (leftHeight + rightHeight) / 2.0;
    double shortSide = std::min(averageWidth, averageHeight);
    double longSide = std::max(averageWidth, averageHeight);
    double ratio = shortSide / std::max(longSide, 1.0);
    double ratioScore = std::max(0.0, 1.0 - std::abs(ratio - targetPhotocardRatio) / 0.14);

    double imageArea = static_cast<double>(imageSize.width) * static_cast<double>(imageSize.height);
    double areaScore = std::min(supportArea / std::max(imageArea, 1.0), 1.0);

    cv::Rect bounds = cv::boundingRect(points);
    double rectangularArea = std::max(static_cast<double>(bounds.area()), 1.0);
    double quadrilateralArea = std::abs(cv::contourArea(ordered));
    double rectangularityScore = std::min(quadrilateralArea / rectangularArea, 1.0);

    cv::Point2f center(0, 0);
    for (const auto &point : points) {
        center += point;
    }
    center *= 0.25f;
    double centerX = center.x / std::max(imageSize.width, 1);
    double centerY = center.y / std::max(imageSize.height, 1);
    double centerDistance = std::hypot(centerX - 0.5, centerY - 0.5);
    double centerScore = std::max(0.0, 1.0 - centerDistance);

    double touchesOuterFramePenalty = (
        bounds.x <= 2
        || bounds.y <= 2
        || bounds.x + bounds.width >= imageSize.width - 2
        || bounds.y + bounds.height >= imageSize.height - 2
    ) ? 0.18 : 0.0;

    return areaScore * 0.42
        + ratioScore * 0.36
        + rectangularityScore * 0.16
        + centerScore * 0.06
        - touchesOuterFramePenalty;
}

bool makeCandidate(
    const std::vector<cv::Point> &contour,
    const cv::Size &imageSize,
    Candidate &candidate
) {
    double imageArea = static_cast<double>(imageSize.width) * static_cast<double>(imageSize.height);
    double contourArea = std::abs(cv::contourArea(contour));
    cv::Rect contourBounds = cv::boundingRect(contour);
    double boundingArea = static_cast<double>(contourBounds.area());
    double fillRatio = contourArea / std::max(boundingArea, 1.0);

    if (std::max(contourArea, boundingArea) < imageArea * 0.025
        || contourArea > imageArea * 0.98) {
        return false;
    }

    std::vector<cv::Point> approximated;
    double perimeter = cv::arcLength(contour, true);
    cv::approxPolyDP(contour, approximated, perimeter * 0.025, true);

    std::vector<cv::Point2f> points;
    if (approximated.size() == 4 && cv::isContourConvex(approximated)) {
        for (const auto &point : approximated) {
            points.emplace_back(static_cast<float>(point.x), static_cast<float>(point.y));
        }
    } else if (std::max(contourArea, boundingArea) > imageArea * 0.025) {
        if (fillRatio < 0.22) {
            return false;
        }

        cv::RotatedRect rectangle = cv::minAreaRect(contour);
        cv::Point2f rectanglePoints[4];
        rectangle.points(rectanglePoints);

        double rectangleArea = std::max(static_cast<double>(rectangle.size.area()), 1.0);
        double rectangleRatio = std::min(rectangle.size.width, rectangle.size.height)
            / std::max(std::max(rectangle.size.width, rectangle.size.height), 1.0f);
        if (boundingArea / rectangleArea < 0.35
            || rectangleRatio < 0.50
            || rectangleRatio > 0.78) {
            return false;
        }

        points.assign(rectanglePoints, rectanglePoints + 4);
    } else {
        return false;
    }

    std::vector<cv::Point2f> refinedPoints;
    EdgeLine topLine;
    EdgeLine rightLine;
    EdgeLine bottomLine;
    EdgeLine leftLine;
    if (refineCornersFromFittedEdges(
        contour,
        points,
        imageSize,
        refinedPoints,
        &topLine,
        &rightLine,
        &bottomLine,
        &leftLine
    )) {
        points = refinedPoints;
        candidate.topLine = topLine;
        candidate.rightLine = rightLine;
        candidate.bottomLine = bottomLine;
        candidate.leftLine = leftLine;
        candidate.hasFittedLines = true;
    }

    candidate.points = orderedClockwisePoints(points);
    candidate.contour = contour;
    candidate.fillRatio = fillRatio;
    double quadrilateralArea = std::abs(cv::contourArea(candidate.points));
    double supportArea = std::max({ contourArea, boundingArea, quadrilateralArea });
    candidate.score = candidateScore(candidate.points, supportArea, imageSize);
    if (!candidate.hasFittedLines && fillRatio < 0.45) {
        candidate.score -= 0.18;
    }
    return true;
}

bool findBestPhotocardCandidate(const cv::Mat &image, Candidate &bestCandidate) {
    cv::Mat gray;
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);

    cv::Mat blurred;
    cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);

    cv::Mat edges;
    cv::Canny(blurred, edges, 30, 110);

    // OpenCV 컨투어 기반으로 카드 외곽선 후보를 찾고 내부 작은 사각형은 면적 점수로 밀어낸다.
    cv::Mat closed;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(7, 7));
    cv::morphologyEx(edges, closed, cv::MORPH_CLOSE, kernel);
    cv::dilate(closed, closed, kernel, cv::Point(-1, -1), 2);

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(closed, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    cv::Mat labImage;
    cv::cvtColor(image, labImage, cv::COLOR_BGR2Lab);

    int borderThickness = std::max(12, std::min(image.cols, image.rows) / 14);
    cv::Mat backgroundMask = cv::Mat::zeros(image.size(), CV_8UC1);
    backgroundMask(cv::Rect(0, 0, image.cols, borderThickness)).setTo(255);
    backgroundMask(cv::Rect(0, image.rows - borderThickness, image.cols, borderThickness)).setTo(255);
    backgroundMask(cv::Rect(0, 0, borderThickness, image.rows)).setTo(255);
    backgroundMask(cv::Rect(image.cols - borderThickness, 0, borderThickness, image.rows)).setTo(255);

    cv::Scalar backgroundMean = cv::mean(labImage, backgroundMask);
    cv::Mat foregroundMask(image.size(), CV_8UC1, cv::Scalar(0));
    for (int y = 0; y < labImage.rows; y += 1) {
        const cv::Vec3b *row = labImage.ptr<cv::Vec3b>(y);
        uchar *maskRow = foregroundMask.ptr<uchar>(y);
        for (int x = 0; x < labImage.cols; x += 1) {
            double lightness = std::abs(row[x][0] - backgroundMean[0]) * 0.55;
            double chromaA = std::abs(row[x][1] - backgroundMean[1]);
            double chromaB = std::abs(row[x][2] - backgroundMean[2]);
            double distance = std::sqrt(lightness * lightness + chromaA * chromaA + chromaB * chromaB);
            if (distance > 18.0) {
                maskRow[x] = 255;
            }
        }
    }

    cv::Mat maskKernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(9, 9));
    cv::morphologyEx(foregroundMask, foregroundMask, cv::MORPH_CLOSE, maskKernel, cv::Point(-1, -1), 2);
    cv::morphologyEx(foregroundMask, foregroundMask, cv::MORPH_OPEN, maskKernel, cv::Point(-1, -1), 1);

    std::vector<std::vector<cv::Point>> foregroundContours;
    cv::findContours(foregroundMask, foregroundContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    contours.insert(contours.end(), foregroundContours.begin(), foregroundContours.end());

    bool found = false;
    Candidate currentCandidate;
    for (const auto &contour : contours) {
        if (!makeCandidate(contour, image.size(), currentCandidate)) {
            continue;
        }

        if (!found || currentCandidate.score > bestCandidate.score) {
            bestCandidate = currentCandidate;
            found = true;
        }
    }

    return found;
}

UIImage *warpImage(const cv::Mat &source, std::vector<cv::Point2f> points, double pointScale) {
    for (auto &point : points) {
        point.x = static_cast<float>(point.x / pointScale);
        point.y = static_cast<float>(point.y / pointScale);
    }

    points = orderedClockwisePoints(points);

    double topWidth = distanceBetween(points[0], points[1]);
    double bottomWidth = distanceBetween(points[3], points[2]);
    double leftHeight = distanceBetween(points[0], points[3]);
    double rightHeight = distanceBetween(points[1], points[2]);

    double outputWidth = std::max(topWidth, bottomWidth);
    double outputHeight = std::max(leftHeight, rightHeight);

    outputWidth = std::clamp(outputWidth, 280.0, static_cast<double>(source.cols));
    outputHeight = std::clamp(outputHeight, 420.0, static_cast<double>(source.rows));

    std::vector<cv::Point2f> destination = {
        cv::Point2f(0, 0),
        cv::Point2f(static_cast<float>(outputWidth - 1), 0),
        cv::Point2f(static_cast<float>(outputWidth - 1), static_cast<float>(outputHeight - 1)),
        cv::Point2f(0, static_cast<float>(outputHeight - 1))
    };

    cv::Mat transform = cv::getPerspectiveTransform(points, destination);
    cv::Mat warpedBGR;
    cv::warpPerspective(
        source,
        warpedBGR,
        transform,
        cv::Size(static_cast<int>(outputWidth), static_cast<int>(outputHeight)),
        cv::INTER_CUBIC
    );

    int insetX = static_cast<int>(std::round(warpedBGR.cols * 0.025));
    int insetY = static_cast<int>(std::round(warpedBGR.rows * 0.025));
    cv::Rect insetRect(
        insetX,
        insetY,
        std::max(warpedBGR.cols - insetX * 2, 1),
        std::max(warpedBGR.rows - insetY * 2, 1)
    );
    cv::Mat insetBGR = warpedBGR(insetRect).clone();

    double currentRatio = static_cast<double>(insetBGR.cols) / std::max(static_cast<double>(insetBGR.rows), 1.0);
    cv::Rect ratioRect(0, 0, insetBGR.cols, insetBGR.rows);
    if (currentRatio > targetPhotocardRatio) {
        int targetWidth = static_cast<int>(std::round(insetBGR.rows * targetPhotocardRatio));
        ratioRect.x = std::max((insetBGR.cols - targetWidth) / 2, 0);
        ratioRect.width = std::min(targetWidth, insetBGR.cols);
    } else {
        int targetHeight = static_cast<int>(std::round(insetBGR.cols / targetPhotocardRatio));
        ratioRect.y = std::max((insetBGR.rows - targetHeight) / 2, 0);
        ratioRect.height = std::min(targetHeight, insetBGR.rows);
    }

    cv::Mat croppedBGR = insetBGR(ratioRect).clone();
    cv::Mat outputBGR;
    cv::resize(croppedBGR, outputBGR, cv::Size(1100, 1700), 0, 0, cv::INTER_AREA);

    cv::Mat warpedRGBA;
    cv::cvtColor(outputBGR, warpedRGBA, cv::COLOR_BGR2RGBA);
    return MatToUIImage(warpedRGBA);
}

void drawEdgeLine(
    cv::Mat &image,
    const EdgeLine &line,
    const cv::Scalar &color
) {
    float length = static_cast<float>(std::max(image.cols, image.rows) * 1.5);
    cv::Point2f start = line.point - line.direction * length;
    cv::Point2f end = line.point + line.direction * length;
    cv::line(image, start, end, color, 3, cv::LINE_AA);
}

UIImage *makeDebugOverlay(const cv::Mat &sourceBGR, const Candidate &candidate) {
    cv::Mat overlay = sourceBGR.clone();

    if (!candidate.contour.empty()) {
        std::vector<std::vector<cv::Point>> contours = { candidate.contour };
        cv::drawContours(overlay, contours, 0, cv::Scalar(0, 255, 0), 2, cv::LINE_AA);
    }

    if (candidate.hasFittedLines) {
        drawEdgeLine(overlay, candidate.topLine, cv::Scalar(255, 0, 255));
        drawEdgeLine(overlay, candidate.rightLine, cv::Scalar(255, 0, 255));
        drawEdgeLine(overlay, candidate.bottomLine, cv::Scalar(255, 0, 255));
        drawEdgeLine(overlay, candidate.leftLine, cv::Scalar(255, 0, 255));
    }

    auto points = orderedClockwisePoints(candidate.points);
    for (int index = 0; index < 4; index += 1) {
        cv::Point2f from = points[index];
        cv::Point2f to = points[(index + 1) % 4];
        cv::line(overlay, from, to, cv::Scalar(255, 180, 0), 4, cv::LINE_AA);
        cv::circle(overlay, from, 9, cv::Scalar(0, 0, 255), -1, cv::LINE_AA);
        cv::putText(
            overlay,
            std::to_string(index + 1),
            cv::Point(static_cast<int>(from.x + 10), static_cast<int>(from.y - 10)),
            cv::FONT_HERSHEY_SIMPLEX,
            0.8,
            cv::Scalar(0, 0, 255),
            2,
            cv::LINE_AA
        );
    }

    cv::putText(
        overlay,
        candidate.hasFittedLines ? "green: contour  magenta: fitted edges  orange/red: virtual corners" : "green: contour  orange/red: fallback corners",
        cv::Point(24, 42),
        cv::FONT_HERSHEY_SIMPLEX,
        0.7,
        cv::Scalar(0, 0, 0),
        5,
        cv::LINE_AA
    );
    cv::putText(
        overlay,
        candidate.hasFittedLines ? "green: contour  magenta: fitted edges  orange/red: virtual corners" : "green: contour  orange/red: fallback corners",
        cv::Point(24, 42),
        cv::FONT_HERSHEY_SIMPLEX,
        0.7,
        cv::Scalar(255, 255, 255),
        2,
        cv::LINE_AA
    );

    cv::Mat overlayRGBA;
    cv::cvtColor(overlay, overlayRGBA, cv::COLOR_BGR2RGBA);
    return MatToUIImage(overlayRGBA);
}

UIImage *makeNoCandidateDebugOverlay(const cv::Mat &sourceBGR) {
    cv::Mat gray;
    cv::cvtColor(sourceBGR, gray, cv::COLOR_BGR2GRAY);

    cv::Mat blurred;
    cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);

    cv::Mat edges;
    cv::Canny(blurred, edges, 30, 110);

    cv::Mat closed;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(7, 7));
    cv::morphologyEx(edges, closed, cv::MORPH_CLOSE, kernel);
    cv::dilate(closed, closed, kernel, cv::Point(-1, -1), 2);

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(closed, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    cv::Mat overlay = sourceBGR.clone();
    std::sort(contours.begin(), contours.end(), [](const auto &lhs, const auto &rhs) {
        return std::abs(cv::contourArea(lhs)) > std::abs(cv::contourArea(rhs));
    });

    int drawCount = std::min(static_cast<int>(contours.size()), 20);
    for (int index = 0; index < drawCount; index += 1) {
        cv::drawContours(overlay, contours, index, cv::Scalar(0, 255, 255), 2, cv::LINE_AA);
    }

    cv::putText(
        overlay,
        "no accepted candidate - yellow: raw contours",
        cv::Point(24, 42),
        cv::FONT_HERSHEY_SIMPLEX,
        0.7,
        cv::Scalar(0, 0, 0),
        5,
        cv::LINE_AA
    );
    cv::putText(
        overlay,
        "no accepted candidate - yellow: raw contours",
        cv::Point(24, 42),
        cv::FONT_HERSHEY_SIMPLEX,
        0.7,
        cv::Scalar(255, 255, 255),
        2,
        cv::LINE_AA
    );

    cv::Mat overlayRGBA;
    cv::cvtColor(overlay, overlayRGBA, cv::COLOR_BGR2RGBA);
    return MatToUIImage(overlayRGBA);
}

bool makeProcessingImage(UIImage *image, cv::Mat &processingImage) {
    cv::Mat sourceRGBA;
    UIImageToMat(image, sourceRGBA);

    if (sourceRGBA.empty()) {
        return false;
    }

    cv::Mat sourceBGR;
    if (sourceRGBA.channels() == 4) {
        cv::cvtColor(sourceRGBA, sourceBGR, cv::COLOR_RGBA2BGR);
    } else if (sourceRGBA.channels() == 3) {
        cv::cvtColor(sourceRGBA, sourceBGR, cv::COLOR_RGB2BGR);
    } else {
        cv::cvtColor(sourceRGBA, sourceBGR, cv::COLOR_GRAY2BGR);
    }

    double largestDimension = std::max(sourceBGR.cols, sourceBGR.rows);
    double scale = largestDimension > maxProcessingDimension
        ? maxProcessingDimension / largestDimension
        : 1.0;

    if (scale < 1.0) {
        cv::resize(sourceBGR, processingImage, cv::Size(), scale, scale, cv::INTER_AREA);
    } else {
        processingImage = sourceBGR;
    }

    return true;
}

}

@implementation OpenCVPhotocardExtractor

+ (UIImage *)extractPhotocardFromImage:(UIImage *)image {
    cv::Mat sourceRGBA;
    UIImageToMat(image, sourceRGBA);

    if (sourceRGBA.empty()) {
        return nil;
    }

    cv::Mat sourceBGR;
    if (sourceRGBA.channels() == 4) {
        cv::cvtColor(sourceRGBA, sourceBGR, cv::COLOR_RGBA2BGR);
    } else if (sourceRGBA.channels() == 3) {
        cv::cvtColor(sourceRGBA, sourceBGR, cv::COLOR_RGB2BGR);
    } else {
        cv::cvtColor(sourceRGBA, sourceBGR, cv::COLOR_GRAY2BGR);
    }

    double largestDimension = std::max(sourceBGR.cols, sourceBGR.rows);
    double scale = largestDimension > maxProcessingDimension
        ? maxProcessingDimension / largestDimension
        : 1.0;

    cv::Mat processingImage;
    if (scale < 1.0) {
        cv::resize(sourceBGR, processingImage, cv::Size(), scale, scale, cv::INTER_AREA);
    } else {
        processingImage = sourceBGR;
    }

    Candidate bestCandidate;
    if (!findBestPhotocardCandidate(processingImage, bestCandidate)) {
        return nil;
    }

    return warpImage(sourceBGR, bestCandidate.points, scale);
}

+ (UIImage *)debugOverlayFromImage:(UIImage *)image {
    cv::Mat processingImage;
    if (!makeProcessingImage(image, processingImage)) {
        return nil;
    }

    Candidate bestCandidate;
    if (!findBestPhotocardCandidate(processingImage, bestCandidate)) {
        return makeNoCandidateDebugOverlay(processingImage);
    }

    return makeDebugOverlay(processingImage, bestCandidate);
}

@end
