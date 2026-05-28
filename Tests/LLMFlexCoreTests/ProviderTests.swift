import XCTest
@testable import LLMFlexCore

final class ProviderTests: XCTestCase {
    func testCodexNativeProviders() {
        let native: Set<Provider> = [.openai, .openrouter, .lmStudio, .openaiCompatible, .custom]
        for p in native {
            XCTAssertEqual(p.codexCompatibility, .native, "\(p) should be native")
            XCTAssertNil(p.codexIncompatibilityReason, "\(p) should not have a reason")
        }
    }

    func testCodexIncompatibleProviders() {
        let incompat: Set<Provider> = [.ollama, .anthropic, .gemini, .opencodeGo]
        for p in incompat {
            XCTAssertEqual(p.codexCompatibility, .incompatible, "\(p) should be incompatible")
            XCTAssertNotNil(p.codexIncompatibilityReason, "\(p) should explain why")
        }
    }

    func testDefaultBaseURLs() {
        XCTAssertEqual(Provider.openai.defaultBaseURL, "https://api.openai.com/v1")
        XCTAssertEqual(Provider.anthropic.defaultBaseURL, "https://api.anthropic.com/v1")
        XCTAssertEqual(Provider.gemini.defaultBaseURL, "https://generativelanguage.googleapis.com/v1beta")
        XCTAssertEqual(Provider.opencodeGo.defaultBaseURL, "https://opencode.ai/zen/go/v1")
        XCTAssertEqual(Provider.lmStudio.defaultBaseURL, "http://localhost:1234/v1")
    }

    func testApiKeyRequirement() {
        XCTAssertFalse(Provider.ollama.requiresAPIKey)
        XCTAssertFalse(Provider.lmStudio.requiresAPIKey)
        XCTAssertTrue(Provider.openai.requiresAPIKey)
        XCTAssertTrue(Provider.anthropic.requiresAPIKey)
        XCTAssertTrue(Provider.gemini.requiresAPIKey)
        XCTAssertTrue(Provider.opencodeGo.requiresAPIKey)
    }
}
