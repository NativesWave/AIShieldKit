import Foundation

/// Output of the high-level `prepareRequest` guard workflow.
public struct PreparedRequest: Sendable, Codable, Equatable {
    public let guardedPrompt: GuardedPrompt
    public let safetyResult: SafetyCheckResult
    public let tokenEstimate: TokenEstimate
    public let costEstimate: CostEstimate?
    public let expectedJSONSchema: JSONStructureSchema?
    public let provider: AIShieldProviderKind
    public let model: String
    public let cacheKey: AIShieldCacheKey

    public init(
        guardedPrompt: GuardedPrompt,
        safetyResult: SafetyCheckResult,
        tokenEstimate: TokenEstimate,
        costEstimate: CostEstimate?,
        expectedJSONSchema: JSONStructureSchema?,
        provider: AIShieldProviderKind,
        model: String,
        cacheKey: AIShieldCacheKey
    ) {
        self.guardedPrompt = guardedPrompt
        self.safetyResult = safetyResult
        self.tokenEstimate = tokenEstimate
        self.costEstimate = costEstimate
        self.expectedJSONSchema = expectedJSONSchema
        self.provider = provider
        self.model = model
        self.cacheKey = cacheKey
    }
}
