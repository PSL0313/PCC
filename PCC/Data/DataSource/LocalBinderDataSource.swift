import Foundation

protocol LocalBinderDataSourceProtocol {
    func loadBinders() throws -> [Binder]
    func saveBinders(_ binders: [Binder]) throws
}

final class LocalBinderDataSource: LocalBinderDataSourceProtocol {
    private let userDefaults: UserDefaults
    private let storageKey = "pcc.local.binders"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadBinders() throws -> [Binder] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        return try JSONDecoder().decode([Binder].self, from: data)
    }

    func saveBinders(_ binders: [Binder]) throws {
        let data = try JSONEncoder().encode(binders)
        userDefaults.set(data, forKey: storageKey)
    }
}
