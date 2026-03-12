import Foundation

/// Heuristic token estimator. Approximate only.
public struct TokenEstimator: TokenEstimating {
    public init() {}

    public func estimate(input: String, expectedOutputLength: Int?) -> TokenEstimate {
        let inputTokens = estimateTokenCount(for: input)
        let outputTokens = expectedOutputLength.map { length in
            estimateTokenCount(forCharacterLength: length)
        }

        return TokenEstimate(
            estimatedInputTokens: inputTokens,
            estimatedOutputTokens: outputTokens
        )
    }

    private func estimateTokenCount(for text: String) -> Int {
        let characters = text.count
        let words = text.split { $0.isWhitespace || $0.isNewline }.count

        let byCharacters = Int(ceil(Double(characters) / 4.0))
        let byWords = Int(ceil(Double(words) * 1.3))

        return max(1, max(byCharacters, byWords))
    }

    private func estimateTokenCount(forCharacterLength length: Int) -> Int {
        guard length > 0 else {
            return 0
        }

        return max(1, Int(ceil(Double(length) / 4.0)))
    }
}
