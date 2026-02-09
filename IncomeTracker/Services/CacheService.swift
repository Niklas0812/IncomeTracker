import Foundation

final class CacheService {
    static let shared = CacheService()
    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {}

    func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: "cache_\(key)")
        }
    }

    func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: "cache_\(key)") else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func clear(forKey key: String) {
        defaults.removeObject(forKey: "cache_\(key)")
    }
}
