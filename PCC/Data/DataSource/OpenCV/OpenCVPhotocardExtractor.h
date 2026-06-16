#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVPhotocardExtractor : NSObject

+ (nullable UIImage *)extractPhotocardFromImage:(UIImage *)image
    NS_SWIFT_NAME(extractPhotocard(from:));

+ (nullable UIImage *)debugOverlayFromImage:(UIImage *)image
    NS_SWIFT_NAME(debugOverlay(from:));

@end

NS_ASSUME_NONNULL_END
