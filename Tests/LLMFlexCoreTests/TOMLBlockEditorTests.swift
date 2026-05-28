import XCTest
@testable import LLMFlexCore

final class TOMLBlockEditorTests: XCTestCase {
    private let editor = TOMLBlockEditor(
        startMarker: "# START",
        endMarker: "# END"
    )

    private let block = "# START\nmodel_provider = \"x\"\nmodel = \"foo\"\n# END"

    func testApplyOntoEmpty() {
        let result = editor.apply(source: "", block: block)
        XCTAssertTrue(result.hasPrefix("# START"))
        XCTAssertTrue(result.contains("# END"))
    }

    func testApplyKeepsExistingSections() {
        let existing = """
        notify = ["foo"]

        [section.one]
        key = "val"
        """
        let result = editor.apply(source: existing, block: block)
        XCTAssertTrue(result.hasPrefix("# START"))
        XCTAssertTrue(result.contains("[section.one]"))
        XCTAssertTrue(result.contains("key = \"val\""))
    }

    func testApplyStripsConflictingTopLevelKeys() {
        let existing = """
        model = "gpt-5.5"
        model_provider = "openai"

        [section]
        model = "scoped"
        """
        let result = editor.apply(
            source: existing,
            block: block,
            stripTopLevelKeys: ["model", "model_provider"]
        )
        // Our block stays, scoped model stays, top-level pre-existing model/model_provider are gone.
        let topLevelModelCount = result
            .components(separatedBy: "\n")
            .prefix(while: { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("[") })
            .filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("model ") || $0.trimmingCharacters(in: .whitespaces).hasPrefix("model=") }
            .count
        XCTAssertEqual(topLevelModelCount, 1, "expected exactly one top-level model =")
        XCTAssertTrue(result.contains("[section]"))
        XCTAssertTrue(result.contains("model = \"scoped\""))
    }

    func testStripIsIdempotent() {
        let withBlock = editor.apply(source: "", block: block)
        let stripped = editor.strip(source: withBlock)
        XCTAssertFalse(stripped.contains("# START"))
        XCTAssertFalse(stripped.contains("# END"))
        XCTAssertTrue(stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testApplyTwiceDoesNotDuplicateBlock() {
        let once = editor.apply(source: "", block: block)
        let twice = editor.apply(source: once, block: block)
        let count = twice.components(separatedBy: "# START").count - 1
        XCTAssertEqual(count, 1)
    }

    func testStripTopLevelOnlyAffectsBeforeFirstSection() {
        let source = """
        model = "x"
        [section]
        model = "y"
        """
        let stripped = editor.stripTopLevel(keys: ["model"], from: source)
        XCTAssertFalse(stripped.contains("model = \"x\""))
        XCTAssertTrue(stripped.contains("model = \"y\""))
    }

    func testStripTopLevelDoesNotMatchSuffixes() {
        // `model_provider` should not be stripped by key `"model"`.
        let source = """
        model_provider = "x"
        """
        let stripped = editor.stripTopLevel(keys: ["model"], from: source)
        XCTAssertTrue(stripped.contains("model_provider = \"x\""))
    }
}
