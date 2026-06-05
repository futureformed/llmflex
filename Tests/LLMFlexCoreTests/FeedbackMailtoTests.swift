import XCTest
@testable import LLMFlexCore

final class FeedbackMailtoTests: XCTestCase {
    func testBuildsValidMailtoURL() {
        let url = FeedbackMailto.build(subject: "Hi", body: "Hello", to: "x@y.cc")
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.absoluteString, "mailto:x@y.cc?subject=Hi&body=Hello")
    }

    func testAmpersandInBodyIsEscapedNotTreatedAsFieldSeparator() {
        let body = "tokens & keys = tricky"
        let url = FeedbackMailto.build(subject: "S", body: body, to: "x@y.cc")
        let s = url!.absoluteString
        // The body's own & / = must be percent-encoded so they don't start a
        // new query field or split a key/value pair.
        XCTAssertTrue(s.contains("%26"), "ampersand should encode to %26: \(s)")
        XCTAssertTrue(s.contains("%3D"), "equals should encode to %3D: \(s)")
        // Exactly one real field separator (between subject and body).
        XCTAssertEqual(s.filter { $0 == "&" }.count, 1)
        // The body must round-trip back to the original via URLComponents.
        let item = URLComponents(string: s)?.queryItems?.first { $0.name == "body" }
        XCTAssertEqual(item?.value, body)
    }

    func testNewlinesEncodeAsPercent0A() {
        let url = FeedbackMailto.build(subject: "S", body: "line1\nline2", to: "x@y.cc")
        XCTAssertTrue(url!.absoluteString.contains("%0A"))
    }

    func testEmojiAndUnicodeSurvive() {
        let body = "great app 🎉 — café"
        let url = FeedbackMailto.build(subject: "S", body: body, to: "x@y.cc")
        XCTAssertNotNil(url)
        let item = URLComponents(string: url!.absoluteString)?.queryItems?.first { $0.name == "body" }
        XCTAssertEqual(item?.value, body)
    }

    func testPlusSignIsEncodedSoItIsNotReadAsSpace() {
        let url = FeedbackMailto.build(subject: "C++ feedback", body: "a+b", to: "x@y.cc")
        let s = url!.absoluteString
        XCTAssertFalse(s.contains("+"), "raw + would be decoded as a space by some clients: \(s)")
        XCTAssertTrue(s.contains("%2B"))
    }

    func testDefaultRecipientIsTheFeedbackAddress() {
        let url = FeedbackMailto.build(subject: "S", body: "B")
        XCTAssertTrue(url!.absoluteString.hasPrefix("mailto:llmflex@holdtight.cc?"))
    }
}
