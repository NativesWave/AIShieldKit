import Foundation

/// Library errors surfaced by AIShieldKit.
public enum AIShieldError: Error, Sendable, Equatable {
    case unsafePrompt(PromptRiskReport)
    case invalidJSON(JSONValidationResult)
    case rateLimited(identifier: String, retryAfter: TimeInterval)
    case cacheFailure
    case unsupportedConfiguration
    case internalFailure(String)
}

extension AIShieldError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unsafePrompt(report):
            return "Prompt blocked due to heuristic risk level: \(report.level)."
        case let .invalidJSON(result):
            return "JSON validation failed: \(result.reasons.joined(separator: "; "))"
        case let .rateLimited(identifier, retryAfter):
            return "Rate limited for key '\(identifier)'. Retry after \(retryAfter)s."
        case .cacheFailure:
            return "Cache operation failed."
        case .unsupportedConfiguration:
            return "Unsupported or invalid AIShield configuration."
        case let .internalFailure(message):
            return "Internal failure: \(message)"
        }
    }
}
