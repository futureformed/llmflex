import XCTest
@testable import LLMFlexCore

final class ResourceBundleLocatorTests: XCTestCase {
    private let a = URL(fileURLWithPath: "/apps/X.app/Contents/Resources/Res.bundle")
    private let b = URL(fileURLWithPath: "/apps/X.app/Res.bundle")

    func testReturnsFirstCandidateThatExists() {
        // Only the second exists → it's chosen.
        let found = ResourceBundleLocator.firstExisting([a, b]) { $0 == self.b }
        XCTAssertEqual(found, b)
    }

    func testPrefersEarlierCandidateWhenMultipleExist() {
        let found = ResourceBundleLocator.firstExisting([a, b]) { _ in true }
        XCTAssertEqual(found, a)
    }

    func testReturnsNilWhenNothingExists_DoesNotTrap() {
        // The whole point: a distributed app where no candidate resolves must
        // get nil (→ graceful fallback), never a fatalError.
        let found = ResourceBundleLocator.firstExisting([a, b]) { _ in false }
        XCTAssertNil(found)
    }

    func testEmptyCandidatesReturnsNil() {
        XCTAssertNil(ResourceBundleLocator.firstExisting([]) { _ in true })
    }
}
