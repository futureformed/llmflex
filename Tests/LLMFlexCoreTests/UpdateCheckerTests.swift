import XCTest
@testable import LLMFlexCore

final class SemanticVersionTests: XCTestCase {
    func testParsesPlainAndPrefixed() {
        XCTAssertEqual(SemanticVersion("1.2.3"), SemanticVersion(major: 1, minor: 2, patch: 3))
        XCTAssertEqual(SemanticVersion("v0.1.0"), SemanticVersion(major: 0, minor: 1, patch: 0))
        XCTAssertEqual(SemanticVersion("V2.0.0"), SemanticVersion(major: 2, minor: 0, patch: 0))
    }

    func testPartialVersionsDefaultMissingComponentsToZero() {
        XCTAssertEqual(SemanticVersion("1"), SemanticVersion(major: 1, minor: 0, patch: 0))
        XCTAssertEqual(SemanticVersion("1.2"), SemanticVersion(major: 1, minor: 2, patch: 0))
    }

    func testDropsPreReleaseAndBuildMetadata() {
        XCTAssertEqual(SemanticVersion("1.2.3-beta.1"), SemanticVersion(major: 1, minor: 2, patch: 3))
        XCTAssertEqual(SemanticVersion("1.2.3+build7"), SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    func testRejectsGarbage() {
        XCTAssertNil(SemanticVersion(""))
        XCTAssertNil(SemanticVersion("abc"))
        XCTAssertNil(SemanticVersion("1.x.0"))
    }

    func testNumericComparisonNotStringComparison() {
        // The trap: "0.10.0" < "0.9.0" as strings, but 0.10.0 is newer.
        XCTAssertTrue(SemanticVersion("0.9.0")! < SemanticVersion("0.10.0")!)
        XCTAssertTrue(SemanticVersion("0.9.9")! < SemanticVersion("1.0.0")!)
        XCTAssertTrue(SemanticVersion("1.2.3")! == SemanticVersion("1.2.3")!)
        XCTAssertFalse(SemanticVersion("2.0.0")! < SemanticVersion("1.9.9")!)
    }
}

final class UpdateCheckerTests: XCTestCase {
    func testParsesReleasesListAndSkipsDrafts() {
        let data = """
        [
          {"tag_name": "v0.2.0", "html_url": "https://gh/r/v0.2.0", "draft": false, "prerelease": true},
          {"tag_name": "v0.3.0-wip", "html_url": "https://gh/r/v0.3.0", "draft": true, "prerelease": true}
        ]
        """.data(using: .utf8)!
        let releases = UpdateChecker.parseReleases(data)
        XCTAssertEqual(releases.map(\.tagName), ["v0.2.0"]) // draft dropped
    }

    func testParseReleasesRejectsMalformed() {
        XCTAssertEqual(UpdateChecker.parseReleases(Data("not json".utf8)).count, 0)
        XCTAssertEqual(UpdateChecker.parseReleases(Data("{}".utf8)).count, 0)
    }

    func testNewestPicksHighestSemverNotListOrder() {
        // List endpoint sorts by date, which may not match version order.
        let releases = [
            LatestRelease(tagName: "v0.9.0", htmlURL: URL(string: "https://gh/9")!),
            LatestRelease(tagName: "v0.10.0", htmlURL: URL(string: "https://gh/10")!),
            LatestRelease(tagName: "nightly", htmlURL: URL(string: "https://gh/n")!),
        ]
        XCTAssertEqual(UpdateChecker.newest(from: releases)?.tagName, "v0.10.0")
    }

    func testNewestReturnsNilWhenNoParseableTags() {
        let releases = [LatestRelease(tagName: "nightly", htmlURL: URL(string: "https://gh/n")!)]
        XCTAssertNil(UpdateChecker.newest(from: releases))
    }

    func testEvaluateOffersNewerRelease() {
        let release = LatestRelease(tagName: "v0.2.0",
                                    htmlURL: URL(string: "https://example.com/r")!)
        XCTAssertEqual(
            UpdateChecker.evaluate(currentVersion: "0.1.0", latest: release),
            .updateAvailable(version: "v0.2.0", url: URL(string: "https://example.com/r")!)
        )
    }

    func testEvaluateSameVersionIsUpToDate() {
        let release = LatestRelease(tagName: "v0.1.0",
                                    htmlURL: URL(string: "https://example.com/r")!)
        XCTAssertEqual(UpdateChecker.evaluate(currentVersion: "0.1.0", latest: release), .upToDate)
    }

    func testEvaluateOlderReleaseIsUpToDate() {
        // Running a dev build ahead of the last release shouldn't prompt.
        let release = LatestRelease(tagName: "v0.1.0",
                                    htmlURL: URL(string: "https://example.com/r")!)
        XCTAssertEqual(UpdateChecker.evaluate(currentVersion: "0.2.0", latest: release), .upToDate)
    }

    func testEvaluateUnparseableVersionsDoNotPrompt() {
        let release = LatestRelease(tagName: "nightly",
                                    htmlURL: URL(string: "https://example.com/r")!)
        XCTAssertEqual(UpdateChecker.evaluate(currentVersion: "0.1.0", latest: release), .upToDate)
        let ok = LatestRelease(tagName: "v0.2.0", htmlURL: URL(string: "https://example.com/r")!)
        XCTAssertEqual(UpdateChecker.evaluate(currentVersion: "", latest: ok), .upToDate)
    }
}
