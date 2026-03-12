import Foundation

/// Supported provider families for reporting and pricing lookup.
public enum AIShieldProviderKind: Hashable, Sendable, Codable {
    case openAI
    case anthropic
    case google
    case custom(String)

    public var identifier: String {
        switch self {
        case .openAI:
            return "openai"
        case .anthropic:
            return "anthropic"
        case .google:
            return "google"
        case let .custom(value):
            return value.lowercased()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue.lowercased() {
        case "openai":
            self = .openAI
        case "anthropic":
            self = .anthropic
        case "google":
            self = .google
        default:
            self = .custom(rawValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .openAI:
            try container.encode("openai")
        case .anthropic:
            try container.encode("anthropic")
        case .google:
            try container.encode("google")
        case let .custom(value):
            try container.encode(value)
        }
    }
}

/// Heuristic risk level for prompt injection and jailbreak-like attempts.
public enum PromptRiskLevel: Int, Sendable, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2

    public static func < (lhs: PromptRiskLevel, rhs: PromptRiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Heuristic output from prompt risk analysis.
public struct PromptRiskReport: Sendable, Codable, Equatable {
    public let level: PromptRiskLevel
    public let triggers: [String]
    public let reasons: [String]
    public let normalizedPrompt: String
    public let suggestedAction: String?

    public init(
        level: PromptRiskLevel,
        triggers: [String],
        reasons: [String],
        normalizedPrompt: String,
        suggestedAction: String? = nil
    ) {
        self.level = level
        self.triggers = triggers
        self.reasons = reasons
        self.normalizedPrompt = normalizedPrompt
        self.suggestedAction = suggestedAction
    }
}

/// Prompt plus normalized form and associated heuristic risk report.
public struct GuardedPrompt: Sendable, Codable, Equatable {
    public let original: String
    public let normalized: String
    public let riskReport: PromptRiskReport

    public init(original: String, normalized: String, riskReport: PromptRiskReport) {
        self.original = original
        self.normalized = normalized
        self.riskReport = riskReport
    }
}

/// Approximate token usage estimate. This is heuristic and not tokenizer-exact.
public struct TokenEstimate: Sendable, Codable, Equatable {
    public let estimatedInputTokens: Int
    public let estimatedOutputTokens: Int?
    public let totalEstimatedTokens: Int

    public init(estimatedInputTokens: Int, estimatedOutputTokens: Int? = nil) {
        self.estimatedInputTokens = max(0, estimatedInputTokens)
        self.estimatedOutputTokens = estimatedOutputTokens
        self.totalEstimatedTokens = max(0, estimatedInputTokens + (estimatedOutputTokens ?? 0))
    }
}

/// Approximate cost estimate derived from user-supplied pricing metadata.
public struct CostEstimate: Sendable, Codable, Equatable {
    public let provider: AIShieldProviderKind
    public let model: String
    public let estimatedInputCost: Decimal
    public let estimatedOutputCost: Decimal?
    public let estimatedTotalCost: Decimal
    public let currency: String

    public init(
        provider: AIShieldProviderKind,
        model: String,
        estimatedInputCost: Decimal,
        estimatedOutputCost: Decimal?,
        estimatedTotalCost: Decimal,
        currency: String
    ) {
        self.provider = provider
        self.model = model
        self.estimatedInputCost = estimatedInputCost
        self.estimatedOutputCost = estimatedOutputCost
        self.estimatedTotalCost = estimatedTotalCost
        self.currency = currency
    }
}

/// Result for lightweight JSON structure validation.
public struct JSONValidationResult: Sendable, Codable, Equatable {
    public let isValid: Bool
    public let missingKeys: [String]
    public let typeMismatches: [String]
    public let extraKeys: [String]
    public let reasons: [String]

    public init(
        isValid: Bool,
        missingKeys: [String],
        typeMismatches: [String],
        extraKeys: [String],
        reasons: [String]
    ) {
        self.isValid = isValid
        self.missingKeys = missingKeys
        self.typeMismatches = typeMismatches
        self.extraKeys = extraKeys
        self.reasons = reasons
    }
}

/// Basic rule-based safety filter result.
public struct SafetyCheckResult: Sendable, Codable, Equatable {
    public let passed: Bool
    public let flags: [String]
    public let reasons: [String]

    public init(passed: Bool, flags: [String], reasons: [String]) {
        self.passed = passed
        self.flags = flags
        self.reasons = reasons
    }
}

/// Behavior when rate limits are exceeded.
public enum RateLimitStrategy: String, Sendable, Codable {
    case rejectNewest
    case queue
    case allowAfterDelay
}

/// In-memory per-key request rate policy.
public struct RateLimitPolicy: Sendable, Codable, Equatable {
    public let maxRequests: Int
    public let interval: TimeInterval
    public let strategy: RateLimitStrategy

    public init(maxRequests: Int, interval: TimeInterval, strategy: RateLimitStrategy = .rejectNewest) {
        self.maxRequests = maxRequests
        self.interval = interval
        self.strategy = strategy
    }
}

/// Public, configurable pricing metadata supplied by integrators.
public struct ModelPricing: Sendable, Codable, Equatable {
    public let provider: AIShieldProviderKind
    public let model: String
    public let inputCostPer1KTokens: Decimal
    public let outputCostPer1KTokens: Decimal?
    public let currency: String

    public init(
        provider: AIShieldProviderKind,
        model: String,
        inputCostPer1KTokens: Decimal,
        outputCostPer1KTokens: Decimal? = nil,
        currency: String = "USD"
    ) {
        self.provider = provider
        self.model = model
        self.inputCostPer1KTokens = inputCostPer1KTokens
        self.outputCostPer1KTokens = outputCostPer1KTokens
        self.currency = currency
    }
}

/// Enabled checks for runtime guard behavior.
public struct AIShieldEnabledChecks: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let promptInjection = AIShieldEnabledChecks(rawValue: 1 << 0)
    public static let safetyFilter = AIShieldEnabledChecks(rawValue: 1 << 1)
    public static let tokenEstimation = AIShieldEnabledChecks(rawValue: 1 << 2)
    public static let costEstimation = AIShieldEnabledChecks(rawValue: 1 << 3)
    public static let jsonValidation = AIShieldEnabledChecks(rawValue: 1 << 4)
    public static let rateLimiting = AIShieldEnabledChecks(rawValue: 1 << 5)
    public static let caching = AIShieldEnabledChecks(rawValue: 1 << 6)

    public static let all: AIShieldEnabledChecks = [
        .promptInjection,
        .safetyFilter,
        .tokenEstimation,
        .costEstimation,
        .jsonValidation,
        .rateLimiting,
        .caching
    ]
}
