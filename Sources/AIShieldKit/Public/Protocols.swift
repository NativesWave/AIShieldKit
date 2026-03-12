import Foundation

/// Contract for heuristic prompt risk analyzers.
public protocol PromptRiskAnalyzing: Sendable {
    func analyze(_ prompt: String) -> PromptRiskReport
}

/// Contract for approximate token estimators.
public protocol TokenEstimating: Sendable {
    func estimate(input: String, expectedOutputLength: Int?) -> TokenEstimate
}

/// Contract for cost estimators based on caller-managed pricing metadata.
public protocol CostEstimating: Sendable {
    func estimate(
        provider: AIShieldProviderKind,
        model: String,
        tokenEstimate: TokenEstimate,
        pricing: ModelPricing
    ) -> CostEstimate
}

/// Contract for lightweight JSON structure validators.
public protocol JSONStructureValidating: Sendable {
    func validate(data: Data, schema: JSONStructureSchema, allowExtraKeys: Bool) -> JSONValidationResult
}

/// Contract for basic rule-based safety filters.
public protocol SafetyFiltering: Sendable {
    func check(text: String, keywords: [String]) -> SafetyCheckResult
}
