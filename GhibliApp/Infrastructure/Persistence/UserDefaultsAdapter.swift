import Foundation

/// Implementação alternativa de StorageAdapter usando UserDefaults
/// Exemplo de Adapter Pattern - pode ser trocado por SwiftDataAdapter sem alterar os Repositories
actor UserDefaultsAdapter: StorageAdapter {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "GhibliApp.Cache."
    
    init() {}
    
    func save<T: Codable & Sendable>(_ value: T, for key: String) async throws {
        let data = try encoder.encode(value)
        UserDefaults.standard.set(data, forKey: keyPrefix + key)
    }
    
    func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + key) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }
    
    func clearAll() async throws {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys
            .filter { $0.hasPrefix(keyPrefix) }
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
