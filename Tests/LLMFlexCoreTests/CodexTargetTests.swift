import XCTest
@testable import LLMFlexCore

final class CodexTargetTests: XCTestCase {
    var tmp: URL!
    var configURL: URL!
    var authURL: URL!
    var target: CodexTarget!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LLMFlexCodexTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        configURL = tmp.appendingPathComponent("config.toml")
        authURL = tmp.appendingPathComponent("auth.json")
        let snapshots = SnapshotStore(root: tmp.appendingPathComponent("snapshots"))
        // Use authURL = /dev/null to make the detector report .unauthed regardless of test FS.
        target = CodexTarget(
            configURL: configURL,
            authURL: authURL,
            snapshots: snapshots,
            detector: CodexAuthStateDetector(authURL: URL(fileURLWithPath: "/dev/null")),
            appController: CodexAppController(bundleIdentifier: "cc.test.does-not-exist")
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    func testApplyWritesBlockAtTopAndStripsConflicts() throws {
        try """
        model = "gpt-5.5"
        model_provider = "openai"

        notify = ["x"]

        [section.foo]
        model = "scoped"
        """.write(to: configURL, atomically: true, encoding: .utf8)

        let p = Profile(name: "OR", provider: .openrouter,
                        baseURL: "https://openrouter.ai/api/v1",
                        modelName: "anthropic/claude-sonnet-4")
        try target.apply(profile: p, apiKey: "sk-test")

        let content = try String(contentsOf: configURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, CodexTarget.blockStartMarker)

        // Exactly one top-level `model = ...` (ours), the scoped one preserved.
        let topLines = lines.prefix(while: { line in
            // Stop counting once we hit the first user-level section header
            // AFTER the managed block.
            !line.trimmingCharacters(in: .whitespaces).hasPrefix("[section.")
        })
        let topLevelModelCount = topLines.filter { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            return (t.hasPrefix("model ") || t.hasPrefix("model=")) && !t.contains("model_provider")
        }.count
        XCTAssertEqual(topLevelModelCount, 1)
        XCTAssertTrue(content.contains("model = \"scoped\""))
        XCTAssertTrue(content.contains("[model_providers.llmflex]"))
        XCTAssertTrue(content.contains("base_url = \"https://openrouter.ai/api/v1\""))
    }

    func testApplyWritesAuthKey() throws {
        try "{}".write(to: authURL, atomically: true, encoding: .utf8)
        let p = Profile(name: "OR", provider: .openrouter,
                        baseURL: "https://openrouter.ai/api/v1",
                        modelName: "anthropic/claude-sonnet-4")
        try target.apply(profile: p, apiKey: "sk-secret")
        let data = try Data(contentsOf: authURL)
        let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(dict["OPENAI_API_KEY"] as? String, "sk-secret")
        XCTAssertEqual(dict["auth_mode"] as? String, "api_key")
        XCTAssertNil(dict["tokens"])
        XCTAssertNil(dict["last_refresh"])
    }

    func testRestoreReturnsOriginalFiles() throws {
        let originalConfig = "model = \"original\"\n"
        let originalAuth = "{\"OPENAI_API_KEY\":\"original-key\",\"tokens\":{\"a\":\"b\"}}"
        try originalConfig.write(to: configURL, atomically: true, encoding: .utf8)
        try originalAuth.write(to: authURL, atomically: true, encoding: .utf8)

        let p = Profile(name: "OR", provider: .openrouter,
                        baseURL: "https://openrouter.ai/api/v1",
                        modelName: "any")
        try target.apply(profile: p, apiKey: "sk-test")
        // Files now mutated.
        XCTAssertNotEqual(try String(contentsOf: configURL, encoding: .utf8), originalConfig)

        let restored = try target.restore()
        XCTAssertTrue(restored)
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), originalConfig)
        XCTAssertEqual(try String(contentsOf: authURL, encoding: .utf8), originalAuth)
    }

    func testInspectReadsManagedBlock() throws {
        let p = Profile(name: "OR", provider: .openrouter,
                        baseURL: "https://openrouter.ai/api/v1",
                        modelName: "anthropic/claude-sonnet-4")
        try "{}".write(to: authURL, atomically: true, encoding: .utf8)
        try target.apply(profile: p, apiKey: "sk-test")
        let status = try target.inspect()
        XCTAssertEqual(status.activeProviderKey, "llmflex")
        XCTAssertEqual(status.activeModel, "anthropic/claude-sonnet-4")
        XCTAssertEqual(status.activeBaseURL, "https://openrouter.ai/api/v1")
        XCTAssertEqual(status.activeProviderLabel, "OpenRouter")
    }

    func testApplyBlockedWhenChatGPTLogin() throws {
        // Point detector at a real file with ChatGPT tokens.
        let chatgptAuth = tmp.appendingPathComponent("chatgpt-auth.json")
        try #"{"tokens":{"access_token":"x"},"last_refresh":"2026-01-01T00:00:00Z"}"#
            .write(to: chatgptAuth, atomically: true, encoding: .utf8)
        let snapshots = SnapshotStore(root: tmp.appendingPathComponent("snapshots-2"))
        let blockedTarget = CodexTarget(
            configURL: configURL,
            authURL: authURL,
            snapshots: snapshots,
            detector: CodexAuthStateDetector(authURL: chatgptAuth),
            appController: CodexAppController(bundleIdentifier: "cc.test.none")
        )
        XCTAssertEqual(try blockedTarget.policy(), .blocked(.chatgptLoginActive))

        let p = Profile(name: "OR", provider: .openrouter, baseURL: "https://x", modelName: "y")
        XCTAssertThrowsError(try blockedTarget.apply(profile: p, apiKey: "sk-test")) { error in
            guard let te = error as? TargetError, case .blocked(.chatgptLoginActive) = te else {
                XCTFail("expected .blocked(.chatgptLoginActive), got \(error)"); return
            }
        }
    }

    func testApplyTwiceIsIdempotent() throws {
        try "{}".write(to: authURL, atomically: true, encoding: .utf8)
        let p = Profile(name: "OR", provider: .openrouter,
                        baseURL: "https://openrouter.ai/api/v1",
                        modelName: "any")
        try target.apply(profile: p, apiKey: "sk-test")
        let firstContent = try String(contentsOf: configURL, encoding: .utf8)
        try target.apply(profile: p, apiKey: "sk-test")
        let secondContent = try String(contentsOf: configURL, encoding: .utf8)
        let blockCount = secondContent.components(separatedBy: CodexTarget.blockStartMarker).count - 1
        XCTAssertEqual(blockCount, 1)
        XCTAssertEqual(firstContent, secondContent)
    }
}
