import Foundation

enum ImageStorageError: Error {
    case directoryUnavailable
}

final class FileImageStorage: ImageStorageProtocol {
    private let fileManager: FileManager
    private let directoryName = "PhotocardImages"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func saveImageData(_ data: Data, preferredExtension: String) throws -> String {
        let directoryURL = try imageDirectoryURL()
        let id = "\(UUID().uuidString).\(preferredExtension)"
        let fileURL = directoryURL.appendingPathComponent(id)
        try data.write(to: fileURL, options: .atomic)
        return id
    }

    func loadImageData(id: String) -> Data? {
        guard let directoryURL = try? imageDirectoryURL() else {
            return nil
        }

        let fileURL = directoryURL.appendingPathComponent(id)
        return try? Data(contentsOf: fileURL)
    }

    func deleteImageData(id: String) throws {
        let fileURL = try imageDirectoryURL().appendingPathComponent(id)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func imageDirectoryURL() throws -> URL {
        guard let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw ImageStorageError.directoryUnavailable
        }

        let directoryURL = documentsURL.appendingPathComponent(
            directoryName,
            isDirectory: true
        )

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }

        return directoryURL
    }
}
