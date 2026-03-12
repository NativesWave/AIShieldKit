import Foundation

/// Basic rule-based content safety filter for keyword patterns.
public struct SafetyFilter: SafetyFiltering {
    public init() {}

    public func check(text: String, keywords: [String]) -> SafetyCheckResult {
        let normalizedText = PromptNormalizer.normalize(text)
        let normalizedKeywords = keywords
            .map { PromptNormalizer.normalize($0) }
            .filter { $0.isEmpty == false }

        guard normalizedKeywords.isEmpty == false else {
            return SafetyCheckResult(
                passed: true,
                flags: [],
                reasons: ["No safety keywords configured."]
            )
        }

        var matched: [String] = []
        for keyword in normalizedKeywords where normalizedText.contains(keyword) {
            matched.append(keyword)
        }

        let uniqueMatches = Array(NSOrderedSet(array: matched)) as? [String] ?? matched

        if uniqueMatches.isEmpty {
            return SafetyCheckResult(
                passed: true,
                flags: [],
                reasons: ["No safety rules matched."]
            )
        }

        let reasons = uniqueMatches.map { "Matched safety rule keyword: '\($0)'." }
        return SafetyCheckResult(passed: false, flags: uniqueMatches, reasons: reasons)
    }
}
