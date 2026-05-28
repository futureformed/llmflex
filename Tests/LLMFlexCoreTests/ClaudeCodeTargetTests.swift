import XCTest
@testable import LLMFlexCore

final class ClaudeCodeTargetTests: XCTestCase {
    var tmp: URL!
    var settingsURL: URL!
    var target: ClaudeCodeTarget!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LLMFlexClaudeCodeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        settingsURL = tmp.appendingPathComponent("settings.json")
        let snapshots = SnapshotStore(root: tmp.appendingPathComponent("snapshots"))
        target = ClaudeCodeTarget(settingsURL: settingsURL, snapshots: snapshots)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    func testApplyMergesIntoExistingSettings() throws {
        let original: [String: Any] = [
            "permissions": ["bash"],
            "apiKeyHelper": "/usr/local/bin/get-key.sh",
            "env": ["MY_OTHER_VAR": "keep-me"]
        ]
        try JSONSerialization.data(withJSONObject: original)
            .write(to: settingsURL)

        let p = Profile(name: "Anthropic",
                        provider: .anthropic,
                        baseURL: "https://api.anthropic.com/v1",
                        modelName: "claude-opus-4-8")
        try target.apply(profile: p, apiKey: "sk-ant-test")

        let data = try Data(contentsOf: settingsURL)
        let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(dict["model"] as? String, "claude-opus-4-8")
        XCTAssertEqual(dict["apiKeyHelper"] as? String, "/usr/local/bin/get-key.sh",
                       "must preserve unrelated user keys")
        let env = try XCTUnwrap(dict["env"] as? [String: Any])
        XCTAssertEqual(env["ANTHROPIC_BASE_URL"] as? String, "https://api.anthropic.com/v1")
        XCTAssertEqual(env["ANTHROPIC_AUTH_TOKEN"] as? String, "sk-ant-test")
        XCTAssertEqual(env["ANTHROPIC_API_KEY"] as? String, "sk-ant-test")
        XCTAssertEqual(env["MY_OTHER_VAR"] as? String, "keep-me",
                       "must preserve unrelated env entries")
    }

    func testApplyOnFreshSettingsFile() throws {
        let p = Profile(name: "Opencode",
                        provider: .opencodeGo,
                        baseURL: "https://opencode.ai/zen/go/v1",
                        modelName: "opencode-go/qwen3.7-max")
        try target.apply(profile: p, apiKey: "sk-zen-test")
        XCTAssertTrue(FileManager.default.fileExists(atPath: settingsURL.path))
    }

    func testRestoreFromSnapshot() throws {
        let original = #"{"permissions":["bash"],"model":"original-model"}"#
        try original.write(to: settingsURL, atomically: true, encoding: .utf8)

        let p = Profile(name: "x", provider: .anthropic,
                        baseURL: "https://api.anthropic.com/v1",
                        modelName: "claude-opus-4-8")
        try target.apply(profile: p, apiKey: "sk-test")
        XCTAssertNotEqual(try String(contentsOf: settingsURL, encoding: .utf8), original)

        let restored = try target.restore()
        XCTAssertTrue(restored)
        XCTAssertEqual(try String(contentsOf: settingsURL, encoding: .utf8), original)
    }

    func testRestoreScrubsWhenNoSnapshot() throws {
        // Simulate a settings.json with mixed user-content + our managed keys,
        // but no snapshot (e.g. file appeared after first launch).
        let payload: [String: Any] = [
            "permissions": ["bash"],
            "model": "claude-opus-4-8",
            "env": [
                "ANTHROPIC_BASE_URL": "https://opencode.ai/zen/go/v1",
                "ANTHROPIC_AUTH_TOKEN": "sk-test",
                "ANTHROPIC_API_KEY": "sk-test",
                "MY_VAR": "keep"
            ]
        ]
        try JSONSerialization.data(withJSONObject: payload).write(to: settingsURL)

        let restored = try target.restore()
        XCTAssertFalse(restored, "no snapshot means we report false")

        let dict = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try Data(contentsOf: settingsURL)) as? [String: Any]
        )
        XCTAssertNil(dict["model"])
        let env = try XCTUnwrap(dict["env"] as? [String: Any])
        XCTAssertNil(env["ANTHROPIC_BASE_URL"])
        XCTAssertNil(env["ANTHROPIC_AUTH_TOKEN"])
        XCTAssertNil(env["ANTHROPIC_API_KEY"])
        XCTAssertEqual(env["MY_VAR"] as? String, "keep")
        XCTAssertEqual(dict["permissions"] as? [String], ["bash"])
    }

    func testInspectReadsActiveSettings() throws {
        let p = Profile(name: "Anthropic", provider: .anthropic,
                        baseURL: "https://api.anthropic.com/v1",
                        modelName: "claude-opus-4-8")
        try target.apply(profile: p, apiKey: "sk-ant")
        let status = try target.inspect()
        XCTAssertEqual(status.target, .claudeCode)
        XCTAssertEqual(status.activeModel, "claude-opus-4-8")
        XCTAssertEqual(status.activeBaseURL, "https://api.anthropic.com/v1")
        XCTAssertEqual(status.activeProviderLabel, "Anthropic")
        XCTAssertEqual(status.authMode, .apiKey)
    }

    func testInspectOnEmptySettings() throws {
        let status = try target.inspect()
        XCTAssertNil(status.activeProviderKey)
        XCTAssertNil(status.activeModel)
        XCTAssertEqual(status.authMode, .unauthed)
    }

    func testPolicyAlwaysAllowed() throws {
        XCTAssertEqual(try target.policy(), .allowed)
    }
}

final class TargetCompatibilityTests: XCTestCase {

    func testCodexCompatibility() {
        // Native
        for p in [Provider.openai, .openrouter, .lmStudio, .openaiCompatible, .custom] {
            XCTAssertEqual(p.compatibility(for: .codex), .native, "\(p) should be Codex-native")
        }
        // Incompatible
        for p in [Provider.ollama, .anthropic, .gemini, .opencodeGo] {
            XCTAssertEqual(p.compatibility(for: .codex), .incompatible, "\(p) should be Codex-incompatible")
        }
    }

    func testClaudeCodeCompatibility() {
        // Native
        for p in [Provider.anthropic, .opencodeGo, .custom] {
            XCTAssertEqual(p.compatibility(for: .claudeCode), .native, "\(p) should be Claude Code native")
        }
        // Incompatible
        for p in [Provider.openai, .openrouter, .lmStudio, .openaiCompatible, .ollama, .gemini] {
            XCTAssertEqual(p.compatibility(for: .claudeCode), .incompatible, "\(p) should be Claude Code incompatible")
        }
    }

    func testReasonsExistForIncompatible() {
        for target in TargetID.allCases {
            for p in Provider.allCases where p.compatibility(for: target) == .incompatible {
                XCTAssertNotNil(p.incompatibilityReason(for: target),
                                "missing reason for \(p) on \(target)")
            }
        }
    }

    func testBackCompatShims() {
        // Confirm legacy single-target API still works for UI call sites.
        XCTAssertEqual(Provider.openai.codexCompatibility, .native)
        XCTAssertEqual(Provider.anthropic.codexCompatibility, .incompatible)
        XCTAssertNotNil(Provider.anthropic.codexIncompatibilityReason)
    }
}
