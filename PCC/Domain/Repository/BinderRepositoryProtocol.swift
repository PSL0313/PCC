import Foundation

protocol BinderRepositoryProtocol {
    func fetchBinders() throws -> [Binder]
    func fetchBinder(id: String) throws -> Binder?
    func createBinder(
        name: String,
        profileImageID: String?,
        backgroundHex: String,
        categories: [String],
        members: [String]
    ) throws -> Binder
    func updateBinder(_ binder: Binder) throws
    func deleteBinder(id: String) throws
    func addPhotocards(_ photocards: [Photocard], to binderID: String) throws
    func updatePhotocard(_ photocard: Photocard, in binderID: String) throws
    func removePhotocard(id: String, from binderID: String) throws
    func removePhotocards(ids: Set<String>, from binderID: String) throws
}
