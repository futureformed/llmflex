import XCTest
@testable import LLMFlexCore

final class ModelCatalogTests: XCTestCase {

    func testCuratedProvidersHaveEntries() {
        for provider in [Provider.openai, .anthropic, .openrouter, .opencodeGo] {
            XCTAssertFalse(ModelCatalog.entries(for: provider).isEmpty,
                           "expected catalog entries for \(provider)")
        }
    }

    func testUncuratedProvidersAreEmpty() {
        for provider in [Provider.openaiCompatible, .custom, .lmStudio, .ollama, .gemini] {
            XCTAssertTrue(ModelCatalog.entries(for: provider).isEmpty,
                          "did not expect entries for \(provider)")
        }
    }

    func testEntryIDsAreUnique() {
        for provider in [Provider.openai, .anthropic, .openrouter, .opencodeGo] {
            let ids = ModelCatalog.entries(for: provider).map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count,
                           "duplicate model IDs in \(provider) catalog")
        }
    }

    func testEveryEntryIDIsNonEmpty() {
        for provider in Provider.allCases {
            for entry in ModelCatalog.entries(for: provider) {
                XCTAssertFalse(entry.id.isEmpty, "empty id in \(provider): \(entry)")
                XCTAssertFalse(entry.label.isEmpty, "empty label in \(provider): \(entry)")
            }
        }
    }

    func testOpenAIIncludesFlagship() {
        let ids = ModelCatalog.openai.map(\.id)
        XCTAssertTrue(ids.contains("gpt-5.5"), "expected gpt-5.5 in OpenAI catalog")
    }

    func testAnthropicIncludesCurrentTrio() {
        let ids = ModelCatalog.anthropic.map(\.id)
        XCTAssertTrue(ids.contains("claude-opus-4-8"))
        XCTAssertTrue(ids.contains("claude-sonnet-4-6"))
        XCTAssertTrue(ids.contains("claude-haiku-4-5"))
    }

    func testOpencodeGoIDsAreNamespaced() {
        for entry in ModelCatalog.opencodeGo {
            XCTAssertTrue(entry.id.hasPrefix("opencode-go/"),
                          "expected opencode-go/ prefix on \(entry.id)")
        }
    }
}
