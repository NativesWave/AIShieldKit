import Foundation

/// Configuration for AIShield runtime behavior.
public struct AIShieldConfiguration: Sendable {
    public var promptRiskThreshold: PromptRiskLevel
    public var enabledChecks: AIShieldEnabledChecks
    public var defaultCacheTTL: TimeInterval
    public var isLoggingEnabled: Bool
    public var safetyKeywordRules: [String]
    public var defaultRateLimitPolicy: RateLimitPolicy?
    public var pricingCatalog: [ModelPricing]
    public var failOnSafetyFilterViolation: Bool

    public init(
        promptRiskThreshold: PromptRiskLevel = .high,
        enabledChecks: AIShieldEnabledChecks = .all,
        defaultCacheTTL: TimeInterval = 300,
        isLoggingEnabled: Bool = false,
        safetyKeywordRules: [String] = AIShieldConfiguration.defaultSafetyKeywords,
        defaultRateLimitPolicy: RateLimitPolicy? = RateLimitPolicy(maxRequests: 60, interval: 60, strategy: .rejectNewest),
        pricingCatalog: [ModelPricing] = [],
        failOnSafetyFilterViolation: Bool = false
    ) {
        self.promptRiskThreshold = promptRiskThreshold
        self.enabledChecks = enabledChecks
        self.defaultCacheTTL = defaultCacheTTL
        self.isLoggingEnabled = isLoggingEnabled
        self.safetyKeywordRules = safetyKeywordRules
        self.defaultRateLimitPolicy = defaultRateLimitPolicy
        self.pricingCatalog = pricingCatalog
        self.failOnSafetyFilterViolation = failOnSafetyFilterViolation
    }

    public static var `default`: AIShieldConfiguration {
        AIShieldConfiguration()
    }

    public static let defaultSafetyKeywords: [String] = [
        "self harm",
        "build a bomb",
        "credit card fraud",
        "malware payload",
        "doxx"
    ]

    public func pricing(for provider: AIShieldProviderKind, model: String) -> ModelPricing? {
        pricingCatalog.first {
            $0.provider.identifier == provider.identifier && $0.model.caseInsensitiveCompare(model) == .orderedSame
        }
    }
}
