import Foundation

/// Lightweight JSON field type set used by AIShieldKit structure validation.
public enum JSONFieldType: String, Sendable, Codable {
    case string
    case number
    case bool
    case object
    case array
    case null
}

/// A single key rule for top-level object validation.
public struct JSONFieldRule: Sendable, Codable, Equatable {
    public let key: String
    public let expectedType: JSONFieldType
    public let required: Bool

    public init(key: String, expectedType: JSONFieldType, required: Bool) {
        self.key = key
        self.expectedType = expectedType
        self.required = required
    }

    public static func required(_ key: String, type: JSONFieldType) -> JSONFieldRule {
        JSONFieldRule(key: key, expectedType: type, required: true)
    }

    public static func optional(_ key: String, type: JSONFieldType) -> JSONFieldRule {
        JSONFieldRule(key: key, expectedType: type, required: false)
    }
}

/// Lightweight structure schema for pragmatic AI response validation.
public enum JSONStructureSchema: Sendable, Codable, Equatable {
    case object([JSONFieldRule])

    public var rootRules: [JSONFieldRule] {
        switch self {
        case let .object(rules):
            return rules
        }
    }
}
