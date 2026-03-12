import Foundation

/// Main facade for AIShieldKit checks and utility services.
public final class AIShield {
    public var configuration: AIShieldConfiguration

    private let guardPipeline: GuardPipeline
    private let tokenEstimator: any TokenEstimating
    private let costEstimator: any CostEstimating
    private let jsonValidator: any JSONStructureValidating
    private let cache: AIShieldCache
    private let rateLimiter: AIShieldRateLimiter

    public init(
        configuration: AIShieldConfiguration = .default,
        promptAnalyzer: any PromptRiskAnalyzing = PromptInjectionDetector(),
        tokenEstimator: any TokenEstimating = TokenEstimator(),
        costEstimator: any CostEstimating = CostEstimator(),
        jsonValidator: any JSONStructureValidating = JSONStructureValidator(),
        safetyFilter: any SafetyFiltering = SafetyFilter(),
        cache: AIShieldCache? = nil,
        rateLimiter: AIShieldRateLimiter? = nil
    ) {
        self.configuration = configuration
        self.guardPipeline = GuardPipeline(promptAnalyzer: promptAnalyzer, safetyFilter: safetyFilter)
        self.tokenEstimator = tokenEstimator
        self.costEstimator = costEstimator
        self.jsonValidator = jsonValidator
        self.cache = cache ?? AIShieldCache(defaultTTL: configuration.defaultCacheTTL)
        self.rateLimiter = rateLimiter ?? AIShieldRateLimiter()
    }

    /// Runs heuristic prompt injection/jailbreak analysis.
    public func analyzePrompt(_ prompt: String) -> PromptRiskReport {
        guardPipeline.analyze(prompt)
    }

    /// Guards prompt text using configured heuristic thresholds.
    public func guardPrompt(_ prompt: String) throws -> GuardedPrompt {
        let result = try guardPipeline.run(prompt: prompt, configuration: configuration)
        return result.guardedPrompt
    }

    /// Approximate token estimate. This is heuristic and not provider-tokenizer exact.
    public func estimateTokens(input: String, expectedOutputLength: Int? = nil) -> TokenEstimate {
        tokenEstimator.estimate(input: input, expectedOutputLength: expectedOutputLength)
    }

    /// Approximate cost estimate from caller-supplied pricing metadata.
    /// Returns `nil` if no matching pricing metadata exists.
    public func estimateCost(
        provider: AIShieldProviderKind,
        model: String,
        tokenEstimate: TokenEstimate,
        pricing: ModelPricing? = nil
    ) -> CostEstimate? {
        guard configuration.enabledChecks.contains(.costEstimation) else {
            return nil
        }

        guard let pricing = pricing ?? configuration.pricing(for: provider, model: model) else {
            return nil
        }

        return costEstimator.estimate(
            provider: provider,
            model: model,
            tokenEstimate: tokenEstimate,
            pricing: pricing
        )
    }

    /// Validates JSON structure against a lightweight schema representation.
    public func validateJSON(
        _ data: Data,
        schema: JSONStructureSchema,
        allowExtraKeys: Bool = false
    ) -> JSONValidationResult {
        jsonValidator.validate(data: data, schema: schema, allowExtraKeys: allowExtraKeys)
    }

    /// Runs basic rule-based content safety checks.
    public func safetyCheck(_ text: String, keywords: [String]? = nil) -> SafetyCheckResult {
        guardPipeline.safetyCheck(text, keywords: keywords ?? configuration.safetyKeywordRules)
    }

    /// Attempts rate limit acquisition for a key under the given policy.
    @discardableResult
    public func acquirePermission(
        for identifier: String,
        policy: RateLimitPolicy? = nil
    ) async throws -> Bool {
        guard configuration.enabledChecks.contains(.rateLimiting) else {
            return true
        }

        guard let activePolicy = policy ?? configuration.defaultRateLimitPolicy else {
            return true
        }

        return try await rateLimiter.acquirePermission(for: identifier, policy: activePolicy)
    }

    /// Reads cached data if present and unexpired.
    public func cachedValue(for key: AIShieldCacheKey) async -> Data? {
        guard configuration.enabledChecks.contains(.caching) else {
            return nil
        }

        return await cache.value(for: key)
    }

    /// Stores data in memory cache with optional TTL override.
    public func cacheValue(_ value: Data, for key: AIShieldCacheKey, ttl: TimeInterval? = nil) async {
        guard configuration.enabledChecks.contains(.caching) else {
            return
        }

        await cache.set(value, for: key, ttl: ttl ?? configuration.defaultCacheTTL)
    }

    /// Removes one cache entry.
    public func removeCachedValue(for key: AIShieldCacheKey) async {
        await cache.removeValue(for: key)
    }

    /// Clears all in-memory cache entries.
    public func clearCache() async {
        await cache.removeAll()
    }

    /// High-level guard workflow before invoking an AI provider.
    /// - Note: Prompt injection and safety checks are heuristic.
    public func prepareRequest(
        prompt: String,
        expectedJSONSchema: JSONStructureSchema? = nil,
        provider: AIShieldProviderKind,
        model: String,
        expectedOutputLength: Int? = nil,
        pricing: ModelPricing? = nil,
        rateLimitIdentifier: String = "default",
        policy: RateLimitPolicy? = nil
    ) async throws -> PreparedRequest {
        if configuration.enabledChecks.contains(.rateLimiting) {
            _ = try await acquirePermission(for: rateLimitIdentifier, policy: policy)
        }

        let pipelineResult = try guardPipeline.run(prompt: prompt, configuration: configuration)

        let tokenEstimate: TokenEstimate
        if configuration.enabledChecks.contains(.tokenEstimation) {
            tokenEstimate = tokenEstimator.estimate(
                input: pipelineResult.guardedPrompt.normalized,
                expectedOutputLength: expectedOutputLength
            )
        } else {
            tokenEstimate = TokenEstimate(estimatedInputTokens: 0, estimatedOutputTokens: 0)
        }

        let costEstimate = estimateCost(
            provider: provider,
            model: model,
            tokenEstimate: tokenEstimate,
            pricing: pricing
        )

        let key = AIShieldCacheKey.fromPrompt(
            pipelineResult.guardedPrompt.normalized,
            provider: provider,
            model: model,
            configurationFingerprint: configurationFingerprint
        )

        if configuration.isLoggingEnabled {
            log("Prepared request with risk=\(pipelineResult.guardedPrompt.riskReport.level) tokens=\(tokenEstimate.totalEstimatedTokens)")
        }

        return PreparedRequest(
            guardedPrompt: pipelineResult.guardedPrompt,
            safetyResult: pipelineResult.safetyResult,
            tokenEstimate: tokenEstimate,
            costEstimate: costEstimate,
            expectedJSONSchema: expectedJSONSchema,
            provider: provider,
            model: model,
            cacheKey: key
        )
    }

    private var configurationFingerprint: String {
        let safetyComponent = configuration.safetyKeywordRules.sorted().joined(separator: ",")
        return "threshold=\(configuration.promptRiskThreshold.rawValue)|checks=\(configuration.enabledChecks.rawValue)|safety=\(safetyComponent)"
    }

    private func log(_ message: String) {
        guard configuration.isLoggingEnabled else {
            return
        }

        print("[AIShieldKit] \(message)")
    }
}
