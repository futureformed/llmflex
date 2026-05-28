import XCTest
@testable import LLMFlexCore

final class CodexAuthStateDetectorTests: XCTestCase {
    private let detector = CodexAuthStateDetector(authURL: URL(fileURLWithPath: "/dev/null"))

    func testChatGPTLoginWhenTokensPresent() {
        let obj: [String: Any] = [
            "auth_mode": "chatgpt",
            "OPENAI_API_KEY": NSNull(),
            "tokens": ["access_token": "ya29.fake", "refresh_token": "rt.fake"],
            "last_refresh": "2026-05-28T08:00:00Z",
        ]
        XCTAssertEqual(detector.classify(obj), .chatgptLogin)
    }

    func testChatGPTLoginEvenIfKeyAlsoSet() {
        // If tokens are present, ChatGPT login takes precedence — Codex.app will refresh.
        let obj: [String: Any] = [
            "OPENAI_API_KEY": "sk-leftover",
            "tokens": ["access_token": "x"],
        ]
        XCTAssertEqual(detector.classify(obj), .chatgptLogin)
    }

    func testAPIKeyMode() {
        let obj: [String: Any] = [
            "auth_mode": "api_key",
            "OPENAI_API_KEY": "sk-or-v1-abc",
        ]
        XCTAssertEqual(detector.classify(obj), .apiKey)
    }

    func testUnauthedWhenAllNull() {
        let obj: [String: Any] = [
            "auth_mode": "api_key",
            "OPENAI_API_KEY": NSNull(),
        ]
        XCTAssertEqual(detector.classify(obj), .unauthed)
    }

    func testUnauthedWhenEmpty() {
        XCTAssertEqual(detector.classify([:]), .unauthed)
    }

    func testKeyPresentButWrongAuthModeIsUnauthed() {
        // Without auth_mode=api_key we don't trust the key — Codex itself won't.
        let obj: [String: Any] = ["OPENAI_API_KEY": "sk-x"]
        XCTAssertEqual(detector.classify(obj), .unauthed)
    }
}
