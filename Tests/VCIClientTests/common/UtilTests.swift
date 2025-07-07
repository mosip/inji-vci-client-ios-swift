import XCTest
@testable import VCIClient

class UtilTests: XCTestCase {
    
    func testGetLogTag_WithTraceabilityId() {
        let className = "TestClass"
        let traceabilityId = "123456"
        
        let logTag = Util.getLogTag(className: className, traceabilityId: traceabilityId)
        
        XCTAssertEqual(logTag, "INJI-VCI-Client : \(className) | traceID \(traceabilityId)")
    }
    
    func testGetLogTag_WithMultipleCallsAndDifferentTraceabilityId() {
        let className = "TestClass"
        let traceabilityId1 = "123456"
        let traceabilityId2 = "789012"
        
        let logTag1 = Util.getLogTag(className: className, traceabilityId: traceabilityId1)
        let logTag2 = Util.getLogTag(className: className, traceabilityId: traceabilityId2)
        
        XCTAssertEqual(logTag1, "INJI-VCI-Client : \(className) | traceID \(traceabilityId1)")
        XCTAssertEqual(logTag2, "INJI-VCI-Client : \(className) | traceID \(traceabilityId2)")
    }
    
    func testConvertToAnyCodable_EmptyDictionary() {
        let input: [String: Any] = [:]
        let result = Util.convertToAnyCodable(dict: input)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testConvertToAnyCodable_SimpleValues() {
        let input: [String: Any] = [
            "stringKey": "stringValue",
            "intKey": 42,
            "boolKey": true
        ]
        
        let result = Util.convertToAnyCodable(dict: input)
        
        XCTAssertEqual(result["stringKey"]?.value as? String, "stringValue")
        XCTAssertEqual(result["intKey"]?.value as? Int, 42)
        XCTAssertEqual(result["boolKey"]?.value as? Bool, true)
    }


}
