import Foundation
@testable import VCIClient
import XCTest

func assertThrowsVCIErrorContainingMessage(
    expectedType: Error.Type,
    expectedCode: String? = nil,
    messageContains expectedMessageFragment: String,
    _ expression: @escaping () async throws -> Any,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected error but got success", file: file, line: line)
    } catch {
        XCTAssertTrue(type(of: error) == expectedType, "Expected type \(expectedType), got \(type(of: error))", file: file, line: line)

        guard let vciError = error as? VCIClientException else {
            XCTFail("Expected VCIClientException but got \(type(of: error))", file: file, line: line)
            return
        }
        if (expectedCode != nil) {
            XCTAssertEqual(vciError.code, expectedCode, file: file, line: line)
        }

        XCTAssertTrue(vciError.message.contains(expectedMessageFragment), "Expected message to contain '\(expectedMessageFragment)', got '\(vciError.message)'", file: file, line: line)
    }
}
