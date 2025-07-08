
import XCTest
@testable import VCIClient

final class DataBase64URLEncodedStringTests: XCTestCase {

    func testEmptyDataReturnsEmptyString() {
        let data = Data()
        XCTAssertEqual(data.base64URLEncodedString(), "")
    }

    func testDataWithoutSpecialCharactersStaysSame() {
        let input = "Hello World!"
        let data = input.data(using: .utf8)!
        let urlSafe = data.base64URLEncodedString()
        
        XCTAssertEqual(urlSafe, "SGVsbG8gV29ybGQh")
    }

    func testDataThatEncodesToPlusIsConverted() {
        // Specific bytes to produce '+'
        let data = Data([0xFB]) // Base64: "+"
        let standardBase64 = data.base64EncodedString()
        let urlSafe = data.base64URLEncodedString()
        
        XCTAssertTrue(standardBase64.contains("+"))
        XCTAssertFalse(urlSafe.contains("+"))
        XCTAssertTrue(urlSafe.contains("-"))
    }

    func testDataThatEncodesToSlashIsConverted() {
        let data = Data([0xFC]) // Base64: "/A=="
        let standardBase64 = data.base64EncodedString()
        let urlSafe = data.base64URLEncodedString()
        
        XCTAssertTrue(standardBase64.contains("/"))
        XCTAssertFalse(urlSafe.contains("/"))
        XCTAssertTrue(urlSafe.contains("_"))
    }

    func testPaddingIsRemoved() {
        let data1 = Data([0xFF])         // 1 byte → 2 padding = → /w==
        let data2 = Data([0xFF, 0xFF])   // 2 bytes → 1 padding = → //8=

        XCTAssertTrue(data1.base64EncodedString().hasSuffix("=="))
        XCTAssertFalse(data1.base64URLEncodedString().contains("="))

        XCTAssertTrue(data2.base64EncodedString().hasSuffix("="))
        XCTAssertFalse(data2.base64URLEncodedString().contains("="))
    }

    func testAllBytes_noIllegalCharactersRemain() {
        let allBytes = Data((0...255).map { UInt8($0) })
        let urlSafe = allBytes.base64URLEncodedString()

        XCTAssertFalse(urlSafe.contains("+"))
        XCTAssertFalse(urlSafe.contains("/"))
        XCTAssertFalse(urlSafe.contains("="))
    }

    func testRandomData_isAlwaysUrlSafe() {
        for _ in 0..<100 {
            var bytes = [UInt8](repeating: 0, count: 32)
            _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            let data = Data(bytes)
            let urlSafe = data.base64URLEncodedString()

            XCTAssertFalse(urlSafe.contains("+"))
            XCTAssertFalse(urlSafe.contains("/"))
            XCTAssertFalse(urlSafe.contains("="))
        }
    }

    func testExampleWithKnownPlusAndSlash() {
        let data = Data([0xFB, 0xEF, 0xFF]) // Base64: "++//"
        let urlSafe = data.base64URLEncodedString()
        XCTAssertEqual(urlSafe, "--__")
    }

}
