import Foundation
import XCTest
@testable import AIShieldKit

final class CacheTests: XCTestCase {
    func testCacheEntryExpiresAfterTTL() async throws {
        let cache = AIShieldCache(defaultTTL: 0.1)
        let key = AIShieldCacheKey.fromPrompt("hello")
        let payload = Data("value".utf8)

        await cache.set(payload, for: key)
        let immediate = await cache.value(for: key)
        XCTAssertEqual(immediate, payload)

        try await Task.sleep(nanoseconds: 200_000_000)
        let expired = await cache.value(for: key)
        XCTAssertNil(expired)
    }

    func testCacheKeyDeterminismForPromptAndPayload() throws {
        let promptKeyA = AIShieldCacheKey.fromPrompt("  Summarize   THIS text ")
        let promptKeyB = AIShieldCacheKey.fromPrompt("summarize this text")
        XCTAssertEqual(promptKeyA, promptKeyB)

        let payloadA = try XCTUnwrap("""
        {"a":1,"b":"x"}
        """.data(using: .utf8))
        let payloadB = try XCTUnwrap("""
        {"b":"x","a":1}
        """.data(using: .utf8))

        let payloadKeyA = AIShieldCacheKey.fromPayload(payloadA)
        let payloadKeyB = AIShieldCacheKey.fromPayload(payloadB)
        XCTAssertEqual(payloadKeyA, payloadKeyB)
    }
}
