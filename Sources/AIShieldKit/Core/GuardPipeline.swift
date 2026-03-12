import Foundation

struct GuardPipelineResult {
    let guardedPrompt: GuardedPrompt
    let safetyResult: SafetyCheckResult
}

struct GuardPipeline {
    private let promptAnalyzer: any PromptRiskAnalyzing
    private let safetyFilter: any SafetyFiltering

    init(promptAnalyzer: any PromptRiskAnalyzing, safetyFilter: any SafetyFiltering) {
        self.promptAnalyzer = promptAnalyzer
        self.safetyFilter = safetyFilter
    }

    func analyze(_ prompt: String) -> PromptRiskReport {
        promptAnalyzer.analyze(prompt)
    }

    func safetyCheck(_ text: String, keywords: [String]) -> SafetyCheckResult {
        safetyFilter.check(text: text, keywords: keywords)
    }

    func run(prompt: String, configuration: AIShieldConfiguration) throws -> GuardPipelineResult {
        let normalizedPrompt = PromptNormalizer.normalize(prompt)

        let riskReport: PromptRiskReport
        if configuration.enabledChecks.contains(.promptInjection) {
            riskReport = promptAnalyzer.analyze(prompt)
        } else {
            riskReport = PromptRiskReport(
                level: .low,
                triggers: [],
                reasons: ["Prompt injection heuristic check disabled."],
                normalizedPrompt: normalizedPrompt,
                suggestedAction: nil
            )
        }

        if riskReport.level >= configuration.promptRiskThreshold {
            throw AIShieldError.unsafePrompt(riskReport)
        }

        let safetyResult: SafetyCheckResult
        if configuration.enabledChecks.contains(.safetyFilter) {
            safetyResult = safetyFilter.check(text: normalizedPrompt, keywords: configuration.safetyKeywordRules)
        } else {
            safetyResult = SafetyCheckResult(passed: true, flags: [], reasons: ["Safety filter disabled."])
        }

        if configuration.failOnSafetyFilterViolation, safetyResult.passed == false {
            let report = PromptRiskReport(
                level: .high,
                triggers: safetyResult.flags,
                reasons: safetyResult.reasons,
                normalizedPrompt: normalizedPrompt,
                suggestedAction: "Revise prompt content or disable failOnSafetyFilterViolation for advisory-only behavior."
            )
            throw AIShieldError.unsafePrompt(report)
        }

        return GuardPipelineResult(
            guardedPrompt: GuardedPrompt(
                original: prompt,
                normalized: normalizedPrompt,
                riskReport: riskReport
            ),
            safetyResult: safetyResult
        )
    }
}
