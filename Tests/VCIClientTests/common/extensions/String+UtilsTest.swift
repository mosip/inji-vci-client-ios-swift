import XCTest
@testable import VCIClient

final class StringOptionalIsBlankTests: XCTestCase {

    func testNilIsBlank() {
        let str: String? = nil
        XCTAssertTrue(str.isBlank(), "nil should be blank")
    }

    func testEmptyStringIsBlank() {
        let str: String? = ""
        XCTAssertTrue(str.isBlank(), "Empty string should be blank")
    }

    func testSpacesOnlyIsBlank() {
        let str: String? = "    "
        XCTAssertTrue(str.isBlank(), "Spaces-only string should be blank")
    }

    func testNonBlankStringIsNotBlank() {
        let str: String? = "Hello"
        XCTAssertFalse(str.isBlank(), "Non-blank string should not be blank")
    }

    func testStringWithSpacesAndTextIsNotBlank() {
        let str: String? = "  Hello  "
        XCTAssertFalse(str.isBlank(), "String with spaces and text should not be blank")
    }
}
