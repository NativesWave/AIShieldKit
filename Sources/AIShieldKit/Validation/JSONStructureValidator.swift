import Foundation

/// Lightweight structural JSON validator (not full JSON Schema and not semantic validation).
public struct JSONStructureValidator: JSONStructureValidating {
    public init() {}

    public func validate(data: Data, schema: JSONStructureSchema, allowExtraKeys: Bool) -> JSONValidationResult {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return JSONValidationResult(
                isValid: false,
                missingKeys: [],
                typeMismatches: [],
                extraKeys: [],
                reasons: ["Input is not valid JSON data: \(error.localizedDescription)"]
            )
        }

        guard let dictionary = object as? [String: Any] else {
            return JSONValidationResult(
                isValid: false,
                missingKeys: [],
                typeMismatches: [],
                extraKeys: [],
                reasons: ["Expected top-level JSON object."]
            )
        }

        let rules = schema.rootRules
        let ruleMap = Dictionary(uniqueKeysWithValues: rules.map { ($0.key, $0) })

        var missingKeys: [String] = []
        var typeMismatches: [String] = []
        var reasons: [String] = []

        for rule in rules {
            let value = dictionary[rule.key]

            if value == nil {
                if rule.required {
                    missingKeys.append(rule.key)
                    reasons.append("Missing required key '\(rule.key)'.")
                }
                continue
            }

            if let value, matches(value: value, expected: rule.expectedType) == false {
                let actual = typeName(for: value)
                let mismatch = "\(rule.key): expected \(rule.expectedType.rawValue), got \(actual)"
                typeMismatches.append(mismatch)
                reasons.append("Type mismatch for key '\(rule.key)': expected \(rule.expectedType.rawValue), got \(actual).")
            }
        }

        let extraKeys: [String]
        if allowExtraKeys {
            extraKeys = []
        } else {
            extraKeys = dictionary.keys
                .filter { ruleMap[$0] == nil }
                .sorted()

            if extraKeys.isEmpty == false {
                reasons.append("Found unexpected keys: \(extraKeys.joined(separator: ", ")).")
            }
        }

        let isValid = missingKeys.isEmpty && typeMismatches.isEmpty && extraKeys.isEmpty

        return JSONValidationResult(
            isValid: isValid,
            missingKeys: missingKeys.sorted(),
            typeMismatches: typeMismatches,
            extraKeys: extraKeys,
            reasons: reasons
        )
    }

    private func matches(value: Any, expected: JSONFieldType) -> Bool {
        switch expected {
        case .string:
            return value is String
        case .number:
            guard let number = value as? NSNumber else {
                return false
            }
            return CFGetTypeID(number) != CFBooleanGetTypeID()
        case .bool:
            guard let number = value as? NSNumber else {
                return false
            }
            return CFGetTypeID(number) == CFBooleanGetTypeID()
        case .object:
            return value is [String: Any]
        case .array:
            return value is [Any]
        case .null:
            return value is NSNull
        }
    }

    private func typeName(for value: Any) -> String {
        switch value {
        case is String:
            return JSONFieldType.string.rawValue
        case is NSNull:
            return JSONFieldType.null.rawValue
        case is [String: Any]:
            return JSONFieldType.object.rawValue
        case is [Any]:
            return JSONFieldType.array.rawValue
        case let number as NSNumber:
            return CFGetTypeID(number) == CFBooleanGetTypeID() ? JSONFieldType.bool.rawValue : JSONFieldType.number.rawValue
        default:
            return String(describing: type(of: value))
        }
    }
}
