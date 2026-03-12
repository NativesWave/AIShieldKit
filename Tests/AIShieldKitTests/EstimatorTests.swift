import XCTest
@testable import AIShieldKit

final class EstimatorTests: XCTestCase {
    func testTokenEstimatorProvidesSanePositiveCounts() {
        let estimator = TokenEstimator()

        let estimate = estimator.estimate(input: "Summarize this article.", expectedOutputLength: 300)

        XCTAssertGreaterThan(estimate.estimatedInputTokens, 0)
        XCTAssertEqual(estimate.totalEstimatedTokens, estimate.estimatedInputTokens + (estimate.estimatedOutputTokens ?? 0))
    }

    func testCostEstimatorMath() {
        let estimator = CostEstimator()
        let pricing = ModelPricing(
            provider: .openAI,
            model: "gpt-4.1-mini",
            inputCostPer1KTokens: 0.50,
            outputCostPer1KTokens: 1.00,
            currency: "USD"
        )
        let tokens = TokenEstimate(estimatedInputTokens: 1_000, estimatedOutputTokens: 500)

        let cost = estimator.estimate(
            provider: .openAI,
            model: "gpt-4.1-mini",
            tokenEstimate: tokens,
            pricing: pricing
        )

        XCTAssertEqual(cost.estimatedInputCost, Decimal(string: "0.5"))
        XCTAssertEqual(cost.estimatedOutputCost, Decimal(string: "0.5"))
        XCTAssertEqual(cost.estimatedTotalCost, Decimal(string: "1"))
        XCTAssertEqual(cost.currency, "USD")
    }
}
