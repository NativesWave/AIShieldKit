import Foundation

enum CanonicalJSON {
    static func canonicalString(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }

        return canonicalString(from: object)
    }

    static func canonicalString(from object: Any) -> String? {
        switch object {
        case let dictionary as [String: Any]:
            let parts = dictionary.keys.sorted().compactMap { key -> String? in
                guard let value = dictionary[key], let canonicalValue = canonicalString(from: value) else {
                    return nil
                }
                return "\(escapedJSONString(key)):\(canonicalValue)"
            }
            return "{\(parts.joined(separator: ","))}"

        case let array as [Any]:
            let parts = array.compactMap(canonicalString(from:))
            guard parts.count == array.count else {
                return nil
            }
            return "[\(parts.joined(separator: ","))]"

        case let string as String:
            return escapedJSONString(string)

        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue

        case is NSNull:
            return "null"

        default:
            return nil
        }
    }

    private static func escapedJSONString(_ string: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [string], options: []),
              var wrapped = String(data: data, encoding: .utf8)
        else {
            return "\"\(string)\""
        }

        wrapped.removeFirst()
        wrapped.removeLast()
        return wrapped
    }
}
