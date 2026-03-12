import Foundation

/// Thread-safe in-memory rate limiter keyed by logical operation id.
public actor AIShieldRateLimiter {
    private var requestBuckets: [String: [Date]] = [:]
    private let now: @Sendable () -> Date
    private let sleeper: @Sendable (UInt64) async throws -> Void

    public init(
        now: @escaping @Sendable () -> Date = Date.init,
        sleeper: @escaping @Sendable (UInt64) async throws -> Void = { nanoseconds in
            try await Task.sleep(nanoseconds: nanoseconds)
        }
    ) {
        self.now = now
        self.sleeper = sleeper
    }

    @discardableResult
    public func acquirePermission(for identifier: String, policy: RateLimitPolicy) async throws -> Bool {
        guard policy.maxRequests > 0, policy.interval > 0 else {
            throw AIShieldError.unsupportedConfiguration
        }

        while true {
            let timestamp = now()
            pruneExpired(for: identifier, policy: policy, now: timestamp)

            var bucket = requestBuckets[identifier] ?? []
            if bucket.count < policy.maxRequests {
                bucket.append(timestamp)
                requestBuckets[identifier] = bucket
                return true
            }

            guard let oldestRequest = bucket.min() else {
                requestBuckets[identifier] = [timestamp]
                return true
            }

            let releaseTime = oldestRequest.addingTimeInterval(policy.interval)
            let retryAfter = max(0, releaseTime.timeIntervalSince(timestamp))

            switch policy.strategy {
            case .rejectNewest:
                throw AIShieldError.rateLimited(identifier: identifier, retryAfter: retryAfter)
            case .queue, .allowAfterDelay:
                if retryAfter == 0 {
                    continue
                }

                let nanos = UInt64((retryAfter * 1_000_000_000).rounded())
                try await sleeper(nanos)
            }
        }
    }

    public func reset(identifier: String? = nil) {
        if let identifier {
            requestBuckets.removeValue(forKey: identifier)
        } else {
            requestBuckets.removeAll()
        }
    }

    private func pruneExpired(for identifier: String, policy: RateLimitPolicy, now: Date) {
        let validThreshold = now.addingTimeInterval(-policy.interval)
        let pruned = (requestBuckets[identifier] ?? []).filter { $0 > validThreshold }
        requestBuckets[identifier] = pruned
    }
}
