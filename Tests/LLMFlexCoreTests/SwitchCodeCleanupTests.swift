import XCTest
@testable import LLMFlexCore

final class SwitchCodeCleanupTests: XCTestCase {
    private let cleaner = SwitchCodeCleanup()

    private let legacyConfig = """
    model = "gpt-5.5"

    [mcp_servers.node_repl]
    command = "/foo"

    # SwitchCode provider configuration
    model_provider = "switchcode"

    [model_providers.switchcode]
    name = "SwitchCode"
    base_url = "https://openrouter.ai/api/v1"
    env_key = "SWITCHCODE_API_KEY"

    [env]
    SWITCHCODE_API_KEY = "sk-or-leaked"
    """

    func testDetectsLegacyArtifacts() {
        XCTAssertTrue(cleaner.needsCleanup(legacyConfig))
    }

    func testCleanRemovesSwitchCodeSection() {
        let cleaned = cleaner.clean(legacyConfig)
        XCTAssertFalse(cleaned.contains("[model_providers.switchcode]"))
        XCTAssertFalse(cleaned.contains("SWITCHCODE_API_KEY"))
        XCTAssertFalse(cleaned.contains("# SwitchCode provider configuration"))
        // Unrelated content preserved.
        XCTAssertTrue(cleaned.contains("[mcp_servers.node_repl]"))
        XCTAssertTrue(cleaned.contains("model = \"gpt-5.5\""))
    }

    func testCleanRemovesOrphanedEnvSection() {
        let cleaned = cleaner.clean(legacyConfig)
        // The `[env]` table only ever held SWITCHCODE_API_KEY; it must not
        // be left as an orphan header.
        XCTAssertFalse(cleaned.contains("[env]"))
    }

    func testCleanPreservesNonOrphanEnvSection() {
        let withRealEnv = """
        [env]
        SWITCHCODE_API_KEY = "sk-leaked"
        OTHER_KEY = "keep me"
        """
        let cleaned = cleaner.clean(withRealEnv)
        XCTAssertTrue(cleaned.contains("[env]"))
        XCTAssertTrue(cleaned.contains("OTHER_KEY"))
        XCTAssertFalse(cleaned.contains("SWITCHCODE_API_KEY"))
    }

    func testCleanCleanContentIsNoop() {
        let pristine = """
        model = "gpt-5.5"

        [section]
        key = "v"
        """
        XCTAssertFalse(cleaner.needsCleanup(pristine))
        XCTAssertEqual(cleaner.clean(pristine), pristine)
    }
}
