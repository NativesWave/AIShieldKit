import Foundation

/// Cost estimator using caller-managed static pricing metadata.
public struct CostEstimator: CostEstimating {
    public init() {}

    public func estimate(
        provider: AIShieldProviderKind,
        model: String,
        tokenEstimate: TokenEstimate,
        pricing: ModelPricing
    ) -> CostEstimate {
        let inputCost = perThousandCost(tokens: tokenEstimate.estimatedInputTokens, rate: pricing.inputCostPer1KTokens)
        let outputCost = pricing.outputCostPer1KTokens.map {
            perThousandCost(tokens: tokenEstimate.estimatedOutputTokens ?? 0, rate: $0)
        }

        let total = (inputCost + (outputCost ?? 0)).rounded(scale: 6)

        return CostEstimate(
            provider: provider,
            model: model,
            estimatedInputCost: inputCost.rounded(scale: 6),
            estimatedOutputCost: outputCost?.rounded(scale: 6),
            estimatedTotalCost: total,
            currency: pricing.currency
        )
    }

    private func perThousandCost(tokens: Int, rate: Decimal) -> Decimal {
        guard tokens > 0 else {
            return 0
        }

        return (Decimal(tokens) / Decimal(1_000) * rate)
    }
}
