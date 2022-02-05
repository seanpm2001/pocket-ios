import XCTest
import Sync
import Combine
import Network
import Analytics

@testable import PocketKit


class ArchivedItemsViewModelTests: XCTestCase {
    var source: MockSource!
    var tracker: MockTracker!
    var networkMonitor: MockNetworkPathMonitor!
    var subscriptions: Set<AnyCancellable> = []

    override func setUp() {
        self.source = MockSource()
        self.tracker = MockTracker()
        self.networkMonitor = MockNetworkPathMonitor()
    }

    override func tearDown() {
        subscriptions = []
    }

    func subject(
        source: Source? = nil,
        tracker: Tracker? = nil,
        networkMonitor: NetworkPathMonitor? = nil
    ) -> ArchivedItemsListViewModel {
        ArchivedItemsListViewModel(
            source: source ?? self.source,
            tracker: tracker ?? self.tracker,
            networkMonitor: networkMonitor ?? self.networkMonitor
        )
    }

    func test_fetch_returnsArchivedItemsFromSource() {
        let archivedItems = [
            ArchivedItem.build(remoteID: "1"),
            ArchivedItem.build(remoteID: "2")
        ]

        source.stubFetchArchivedItems {
            return archivedItems
        }

        let viewModel = subject()

        let expectEmptySnapshot = expectation(description: "expect empty snapshot")
        let expectInitialSnapshot = expectation(description: "expect initial snapshot")
        viewModel.events.sink { event in
            guard case .snapshot(let snapshot) = event else {
                return
            }

            if snapshot.itemIdentifiers(inSection: .items).isEmpty {
                expectEmptySnapshot.fulfill()
                return
            }

            if snapshot.itemIdentifiers(inSection: .items).count == 2 {
                XCTAssertEqual(snapshot.itemIdentifiers(inSection: .items), [.item("1"), .item("2")])
                expectInitialSnapshot.fulfill()
                return
            }
        }.store(in: &subscriptions)

        viewModel.fetch()
        wait(for: [expectEmptySnapshot, expectInitialSnapshot], timeout: 1)

        XCTAssertEqual(
            viewModel.item(with: "1")?.attributedTitle.string,
            "http://example.com"
        )
    }

    func test_deleteAction_delegatesToSource_andUpdatesSnapshot() {
        source.stubDelete { _ in }
        source.stubFetchArchivedItems {
            [ArchivedItem.build(remoteID: "1"), ArchivedItem.build(remoteID: "2")]
        }

        let viewModel = subject()

        let expectEmptySnapshot = expectation(description: "expect empty snapshot")
        let expectInitialSnapshot = expectation(description: "expect initial snapshot")
        let expectSnapshotWithItemRemoved = expectation(description: "expected deleted item snapshot")
        viewModel.events.sink { event in
            guard case .snapshot(let snapshot) = event else {
                return
            }

            if snapshot.itemIdentifiers(inSection: .items).isEmpty {
                expectEmptySnapshot.fulfill()
                return
            }

            if snapshot.itemIdentifiers(inSection: .items).count == 2 {
                expectInitialSnapshot.fulfill()
                return
            }

            if snapshot.itemIdentifiers(inSection: .items).count == 1 {
                XCTAssertEqual(
                    snapshot.itemIdentifiers(inSection: .items),
                    [.item("2")]
                )

                expectSnapshotWithItemRemoved.fulfill()
                return
            }

            XCTFail("Received unexepected snapshot event: \(snapshot)")
        }.store(in: &subscriptions)
        viewModel.fetch()
        wait(for: [expectEmptySnapshot, expectInitialSnapshot], timeout: 1)

        // Tap delete button in overflow menu
        viewModel.overflowActions(for: "1")?
            .first { $0.title == "Delete" }?
            .handler?(nil)

        // Tap "Yes" on confirmation alert
        viewModel.presentedAlert?
            .actions
            .first { $0.title == "Yes" }?.invoke()

        wait(for: [expectSnapshotWithItemRemoved], timeout: 1)
        XCTAssertNotNil(source.deleteArchivedItemCall(at: 0))
    }

        let expectSnapshot = expectation(description: "expect a snapshot")
        viewModel.events.sink { event in
            guard case .snapshot(let snapshot) = event else {
                return
            }

            defer { expectSnapshot.fulfill() }
            XCTAssertFalse(snapshot.itemIdentifiers(inSection: .items).contains(.item("1")))
        }.store(in: &subscriptions)

        viewModel.presentedAlert?.actions.first { $0.title == "Yes" }?.invoke()

        wait(for: [expectSnapshot], timeout: 1)
        XCTAssertNotNil(source.deleteArchivedItemCall(at: 0))
    }
}
