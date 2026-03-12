import Foundation

/// Heuristic prompt injection / jailbreak phrase detector.
public struct PromptInjectionDetector: PromptRiskAnalyzing {
    private struct Rule {
        let phrase: String
        let weight: Int
        let reason: String
    }

    private let rules: [Rule]
    private let regexRules: [(regex: NSRegularExpression, weight: Int, reason: String, trigger: String)]

    public init() {
        self.rules = [
            Rule(phrase: "ignore previous instructions", weight: 3, reason: "Attempts to override existing instruction hierarchy."),
            Rule(phrase: "reveal system prompt", weight: 3, reason: "Requests disclosure of protected system instructions."),
            Rule(phrase: "bypass safety", weight: 3, reason: "Explicit attempt to disable safety controls."),
            Rule(phrase: "act as developer mode", weight: 2, reason: "Attempts to switch to privileged/developer behavior."),
            Rule(phrase: "you are no longer bound", weight: 2, reason: "Attempts to remove governance constraints."),
            Rule(phrase: "jailbreak", weight: 2, reason: "References jailbreak behavior explicitly.")
        ]

        self.regexRules = [
            (
                regex: try! NSRegularExpression(pattern: #"\b(ignore|disregard)\b.{0,25}\b(previous|above|prior)\b.{0,25}\b(instruction|instructions|rules?)\b"#),
                weight: 2,
                reason: "Pattern suggests instruction override behavior.",
                trigger: "instruction_override_pattern"
            ),
            (
                regex: try! NSRegularExpression(pattern: #"\b(reveal|show|print|leak)\b.{0,20}\b(system prompt|hidden prompt|policy)\b"#),
                weight: 2,
                reason: "Pattern suggests protected prompt disclosure request.",
                trigger: "system_prompt_exfiltration_pattern"
            )
        ]
    }

    public func analyze(_ prompt: String) -> PromptRiskReport {
        let normalized = PromptNormalizer.normalize(prompt)
        guard normalized.isEmpty == false else {
            return PromptRiskReport(
                level: .low,
                triggers: [],
                reasons: ["Prompt was empty after normalization."],
                normalizedPrompt: normalized,
                suggestedAction: nil
            )
        }

        var score = 0
        var triggers: [String] = []
        var reasons: [String] = []

        for rule in rules where normalized.contains(rule.phrase) {
            score += rule.weight
            triggers.append(rule.phrase)
            reasons.append(rule.reason)
        }

        let fullRange = NSRange(location: 0, length: normalized.utf16.count)
        for rule in regexRules where rule.regex.firstMatch(in: normalized, options: [], range: fullRange) != nil {
            score += rule.weight
            triggers.append(rule.trigger)
            reasons.append(rule.reason)
        }

        let level: PromptRiskLevel
        switch score {
        case 0 ... 1:
            level = .low
        case 2 ... 3:
            level = .medium
        default:
            level = .high
        }

        let suggestedAction: String?
        switch level {
        case .low:
            suggestedAction = nil
        case .medium:
            suggestedAction = "Review prompt intent before sending to a provider."
        case .high:
            suggestedAction = "Block or require explicit user confirmation before sending this prompt."
        }

        return PromptRiskReport(
            level: level,
            triggers: Array(NSOrderedSet(array: triggers)) as? [String] ?? triggers,
            reasons: reasons.isEmpty ? ["No known injection/jailbreak heuristics were triggered."] : reasons,
            normalizedPrompt: normalized,
            suggestedAction: suggestedAction
        )
    }
}
