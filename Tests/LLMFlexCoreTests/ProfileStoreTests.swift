import XCTest
@testable import LLMFlexCore

final class ProfileStoreTests: XCTestCase {
    var defaults: UserDefaults!
    var store: ProfileStore!
    let suite = "ProfileStoreTests-\(UUID().uuidString)"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        store = ProfileStore(defaults: defaults,
                             profilesKey: "profiles",
                             activeKey: "active")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testRoundTrip() {
        let p1 = Profile(name: "A", provider: .openrouter, baseURL: "https://x", modelName: "m1")
        let p2 = Profile(name: "B", provider: .ollama, modelName: "qwen")
        store.upsert(p1)
        store.upsert(p2)
        let loaded = store.all()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.map(\.name).sorted(), ["A", "B"])
    }

    func testUpsertUpdatesByID() {
        var p = Profile(name: "A", provider: .openrouter)
        store.upsert(p)
        p.name = "A renamed"
        store.upsert(p)
        XCTAssertEqual(store.all().count, 1)
        XCTAssertEqual(store.all()[0].name, "A renamed")
    }

    func testDeleteClearsActive() {
        let p = Profile(name: "A", provider: .openrouter)
        store.upsert(p)
        store.activeID = p.id
        store.delete(id: p.id)
        XCTAssertTrue(store.all().isEmpty)
        XCTAssertNil(store.activeID)
    }
}
