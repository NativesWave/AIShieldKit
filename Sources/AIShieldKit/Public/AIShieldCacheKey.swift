import Foundation

/// Deterministic cache key for request/response caching.
public struct AIShieldCacheKey: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Generates a deterministic key for prompt + optional provider/model/config context.
    public static func fromPrompt(
        _ prompt: String,
        provider: AIShieldProviderKind? = nil,
        model: String? = nil,
        configurationFingerprint: String? = nil
    ) -> AIShieldCacheKey {
        let normalizedPrompt = PromptNormalizer.normalize(prompt)
        var components = [
            "prompt=\(normalizedPrompt)",
            "provider=\(provider?.identifier ?? "")",
            "model=\(model?.lowercased() ?? "")"
        ]

        if let configurationFingerprint {
            components.append("config=\(configurationFingerprint)")
        }

        return AIShieldCacheKey(rawValue: DeterministicHasher.fnv1a64Hex(components.joined(separator: "|")))
    }

    /// Generates a deterministic key for arbitrary payload bytes.
    /// If payload is JSON, the key is canonicalized so dictionary key ordering does not change the result.
    public static func fromPayload(_ payload: Data) -> AIShieldCacheKey {
        if let canonical = CanonicalJSON.canonicalString(from: payload) {
            return AIShieldCacheKey(rawValue: DeterministicHasher.fnv1a64Hex(canonical))
        }

        return AIShieldCacheKey(rawValue: DeterministicHasher.fnv1a64Hex(payload))
    }

    public var description: String {
        rawValue
    }
}
