import XCTest
@testable import LLMFlexCore

final class LLMFlexCoreTests: XCTestCase {
    func testScaffoldVersion() {
        XCTAssertFalse(LLMFlexCore.version.isEmpty)
    }
}
