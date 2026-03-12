import Foundation
import XCTest
@testable import AIShieldKit

private final class LockedClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(start: Date) {
        self.current = start
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        current = current.addingTimeInterval(interval)
        lock.unlock()
    }
}

final class RateLimiterTests: XCTestCase {
    func testRejectNewestStrategyThrowsWhenLimitExceeded() async throws {
        let limiter = AIShieldRateLimiter()
        let policy = RateLimitPolicy(maxRequests: 2, interval: 1, strategy: .rejectNewest)

        _ = try await limiter.acquirePermission(for: "chat", policy: policy)
        _ = try await limiter.acquirePermission(for: "chat", policy: policy)

        do {
            _ = try await limiter.acquirePermission(for: "chat", policy: policy)
            XCTFail("Expected rate limited error")
        } catch let AIShieldError.rateLimited(identifier, retryAfter) {
            XCTAssertEqual(identifier, "chat")
            XCTAssertGreaterThanOrEqual(retryAfter, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAllowAfterDelayStrategyWaitsAndAllows() async throws {
        let clock = LockedClock(start: Date(timeIntervalSince1970: 0))
        let limiter = AIShieldRateLimiter(
            now: { clock.now() },
            sleeper: { nanoseconds in
                let seconds = TimeInterval(nanoseconds) / 1_000_000_000
                clock.advance(by: seconds)
            }
        )
        let policy = RateLimitPolicy(maxRequests: 1, interval: 5, strategy: .allowAfterDelay)

        _ = try await limiter.acquirePermission(for: "chat", policy: policy)
        let before = clock.now()

        _ = try await limiter.acquirePermission(for: "chat", policy: policy)
        let after = clock.now()

        XCTAssertGreaterThanOrEqual(after.timeIntervalSince(before), 5)
    }
}
