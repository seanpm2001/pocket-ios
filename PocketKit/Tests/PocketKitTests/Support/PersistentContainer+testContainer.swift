@testable import Sync

extension PersistentContainer {
    static let testContainer = PersistentContainer(storage: .inMemory, userDefaults: .standard, groupID: "group.com.ideashower.ReadItLaterPro")
}

extension Space {
    static func testSpace() -> Space {
        return PersistentContainer.testContainer.rootSpace
    }
}
