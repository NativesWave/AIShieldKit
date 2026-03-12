import Foundation

/// Thread-safe in-memory cache with TTL.
public actor AIShieldCache {
    private struct Entry {
        let value: Data
        let expiresAt: Date?

        func isExpired(at date: Date) -> Bool {
            guard let expiresAt else {
                return false
            }
            return date >= expiresAt
        }
    }

    private var storage: [AIShieldCacheKey: Entry] = [:]
    private let defaultTTL: TimeInterval

    public init(defaultTTL: TimeInterval = 300) {
        self.defaultTTL = max(0, defaultTTL)
    }

    public func set(_ value: Data, for key: AIShieldCacheKey, ttl: TimeInterval? = nil) {
        let effectiveTTL = max(0, ttl ?? defaultTTL)
        let expiration = effectiveTTL == 0 ? Date() : Date().addingTimeInterval(effectiveTTL)
        storage[key] = Entry(value: value, expiresAt: expiration)
    }

    public func value(for key: AIShieldCacheKey) -> Data? {
        cleanupExpiredEntries(now: Date())

        guard let entry = storage[key] else {
            return nil
        }

        if entry.isExpired(at: Date()) {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    public func removeValue(for key: AIShieldCacheKey) {
        storage.removeValue(forKey: key)
    }

    public func removeAll() {
        storage.removeAll()
    }

    public func count() -> Int {
        cleanupExpiredEntries(now: Date())
        return storage.count
    }

    private func cleanupExpiredEntries(now: Date) {
        storage = storage.filter { _, entry in
            entry.isExpired(at: now) == false
        }
    }
}
