import Foundation

protocol ImageStorageProtocol {
    func saveImageData(_ data: Data, preferredExtension: String) throws -> String
    func loadImageData(id: String) -> Data?
    func deleteImageData(id: String) throws
}
