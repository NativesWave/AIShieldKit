import XCTest
@testable import AIShieldKit

final class JSONStructureValidatorTests: XCTestCase {
    private let validator = JSONStructureValidator()

    func testValidStructurePasses() throws {
        let schema: JSONStructureSchema = .object([
            .required("title", type: .string),
            .required("summary", type: .string),
            .optional("score", type: .number)
        ])

        let data = try XCTUnwrap("""
        {"title":"Hello","summary":"World","score":0.98}
        """.data(using: .utf8))

        let result = validator.validate(data: data, schema: schema, allowExtraKeys: false)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.missingKeys.isEmpty)
        XCTAssertTrue(result.typeMismatches.isEmpty)
        XCTAssertTrue(result.extraKeys.isEmpty)
    }

    func testMissingTypeMismatchAndExtraKeyAreReported() throws {
        let schema: JSONStructureSchema = .object([
            .required("title", type: .string),
            .required("summary", type: .string),
            .optional("score", type: .number)
        ])

        let data = try XCTUnwrap("""
        {"title":42,"extra":"x"}
        """.data(using: .utf8))

        let result = validator.validate(data: data, schema: schema, allowExtraKeys: false)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.missingKeys, ["summary"])
        XCTAssertTrue(result.typeMismatches.contains(where: { $0.contains("title") && $0.contains("expected string") }))
        XCTAssertEqual(result.extraKeys, ["extra"])
    }
}
