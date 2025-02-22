// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Sync
import Combine
import UIKit
import CoreData
import Analytics
import Localization
import SharedPocketKit

enum ReadableType {
    case recommendation(RecommendationViewModel)
    case savedItem(SavedItemViewModel)
    case webViewRecommendation(RecommendationViewModel)
    case webViewSavedItem(SavedItemViewModel)
    case collection(CollectionViewModel)

    func clearIsPresentingReaderSettings() {
        switch self {
        case .recommendation(let recommendationViewModel):
            recommendationViewModel.clearIsPresentingReaderSettings()
        case .savedItem(let savedItemViewModel):
            savedItemViewModel.clearIsPresentingReaderSettings()
        case .webViewRecommendation(let recommendationViewModel):
            recommendationViewModel.clearPresentedWebReaderURL()
        case .webViewSavedItem(let savedItemViewModel):
            savedItemViewModel.clearPresentedWebReaderURL()
        case .collection:
            // TODO: NATIVECOLLECTIONS - we might need to do some additional cleanup here
            break
        }
    }
}

enum ReadableSource {
    case app
    case widget
}

enum SeeAll {
    case saves
    case slate(SlateDetailViewModel)

    func clearRecommendationToReport() {
        switch self {
        case .saves:
            break
        case .slate(let viewModel):
            viewModel.clearRecommendationToReport()
        }
    }

    func clearPresentedWebReaderURL() {
        switch self {
        case .saves:
            break
        case .slate(let viewModel):
            viewModel.clearPresentedWebReaderURL()
        }
    }

    func clearSharedActivity() {
        switch self {
        case .saves:
            break
        case .slate(let viewModel):
            viewModel.clearSharedActivity()
        }
    }

    func clearIsPresentingReaderSettings() {
        switch self {
        case .saves:
            break
        case .slate(let viewModel):
            viewModel.clearIsPresentingReaderSettings()
        }
    }

    func clearSelectedItem() {
        switch self {
        case .saves:
            break
        case .slate(let viewModel):
            viewModel.clearSelectedItem()
        }
    }
}

@MainActor
class HomeViewModel: NSObject {
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Cell>
    typealias ItemIdentifier = NSManagedObjectID

    @Published var snapshot: Snapshot

    @Published var sharedActivity: PocketActivity?

    @Published var presentedAlert: PocketAlert?

    @Published var selectedReadableType: ReadableType?

    @Published var selectedRecommendationToReport: Recommendation?

    @Published var tappedSeeAll: SeeAll?

    var numberOfHeroItems: Int = 1 {
        didSet {
            self.snapshot = buildSnapshot()
        }
    }

    private let source: Source
    let tracker: Tracker
    private let user: User
    private let userDefaults: UserDefaults
    private let networkPathMonitor: NetworkPathMonitor
    private let homeRefreshCoordinator: RefreshCoordinator
    private let notificationCenter: NotificationCenter
    private var subscriptions: [AnyCancellable] = []
    private var recentSavesCount: Int = 0
    private let featureFlags: FeatureFlagServiceProtocol
    private let store: SubscriptionStore
    private let recentSavesWidgetUpdateService: RecentSavesWidgetUpdateService
    private let recommendationsWidgetUpdateService: RecommendationsWidgetUpdateService

    private let recentSavesController: NSFetchedResultsController<SavedItem>
    private let recomendationsController: RichFetchedResultsController<Recommendation>

    init(
        source: Source,
        tracker: Tracker,
        networkPathMonitor: NetworkPathMonitor,
        homeRefreshCoordinator: RefreshCoordinator,
        user: User,
        store: SubscriptionStore,
        recentSavesWidgetUpdateService: RecentSavesWidgetUpdateService,
        recommendationsWidgetUpdateService: RecommendationsWidgetUpdateService,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter,
        featureFlags: FeatureFlagServiceProtocol
    ) {
        self.source = source
        self.tracker = tracker
        self.networkPathMonitor = networkPathMonitor
        networkPathMonitor.start(queue: .global(qos: .utility))
        self.homeRefreshCoordinator = homeRefreshCoordinator
        self.user = user
        self.store = store
        self.recentSavesWidgetUpdateService = recentSavesWidgetUpdateService
        self.recommendationsWidgetUpdateService = recommendationsWidgetUpdateService
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.featureFlags = featureFlags

        self.snapshot = {
            return Self.loadingSnapshot()
        }()

        self.recentSavesController = source.makeRecentSavesController()
        self.recomendationsController = source.makeHomeController()

        super.init()
        self.recentSavesController.delegate = self
        self.recomendationsController.delegate = self

        networkPathMonitor.updateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.refresh(isForced: false) { }
            }
        }
        fetch()
    }

    var isOffline: Bool {
        networkPathMonitor.currentNetworkPath.status != .satisfied
    }

    /// Fetch the latest data from core data and get the NSFetechedResults Controllers subscribing to updates
    func fetch() {
        do {
            try self.recentSavesController.performFetch()
            try self.recomendationsController.performFetch()
        } catch {
            Log.capture(error: error)
        }
    }

    /// Refresh of data triggered
    /// - Parameters:
    ///   - isForced: Whether or not the user forced the refresh
    ///   - completion: Completion block to call
    func refresh(isForced: Bool = false, _ completion: @escaping () -> Void) {
        fetch()

        guard !isOffline else {
            completion()
            return
        }

        homeRefreshCoordinator.refresh(isForced: isForced) {
            completion()
        }
    }
}

// MARK: - Snapshot building
extension HomeViewModel {
    private func buildSnapshot() -> Snapshot {
        let recentSaves = self.recentSavesController.fetchedObjects

        var snapshot = Snapshot()

        if let recentSaves, !recentSaves.isEmpty {
            recentSavesCount = recentSaves.count
            snapshot.appendSections([.recentSaves])
            snapshot.appendItems(
                recentSaves.map { .recentSaves($0.objectID) },
                toSection: .recentSaves
            )
        }

        guard !isOffline else {
            snapshot.appendSections([.offline])
            snapshot.appendItems([.offline], toSection: .offline)
            return snapshot
        }

        guard let slateSections = self.recomendationsController.sections, !slateSections.isEmpty else {
            snapshot.appendSections([.loading])
            snapshot.appendItems([.loading], toSection: .loading)
            return snapshot
        }

        for slateSection in slateSections {
            guard var recommendations = slateSection.objects as? [Recommendation],
                  let slateId = recommendations.first?.slate?.objectID
            else {
                continue
            }

            let hero = recommendations.removeFirst()
            snapshot.appendSections([.slateHero(slateId)])
            snapshot.appendItems(
                [.recommendationHero(hero.objectID)],
                toSection: .slateHero(slateId)
            )

            if numberOfHeroItems == 2 {
                let hero2 = recommendations.removeFirst()
                snapshot.appendItems(
                    [.recommendationHero(hero2.objectID)],
                    toSection: .slateHero(slateId)
                )
            }

            guard !recommendations.isEmpty else {
                continue
            }

            snapshot.appendSections([.slateCarousel(slateId)])
            snapshot.appendItems(
                recommendations.prefix(4).map { .recommendationCarousel($0.objectID) },
                toSection: .slateCarousel(slateId)
            )
        }

        return snapshot
    }
}

// MARK: - Cell Selection
extension HomeViewModel {
    func select(cell: HomeViewModel.Cell, at indexPath: IndexPath) {
        switch cell {
        case .loading, .offline:
            return
        case .recentSaves(let objectID):
            guard let savedItem = source.viewObject(id: objectID) as? SavedItem else {
                return
            }

            select(savedItem: savedItem, at: indexPath)
        case .recommendationHero(let objectID), .recommendationCarousel(let objectID):
            guard let recommendation = source.viewObject(id: objectID) as? Recommendation else {
                return
            }

            select(recommendation: recommendation, at: indexPath)
        }
    }

    private func select(slate: Slate) {
        tappedSeeAll = .slate(SlateDetailViewModel(
            slate: slate,
            source: source,
            tracker: tracker.childTracker(hosting: .slateDetail.screen),
            user: user,
            store: store,
            userDefaults: userDefaults,
            networkPathMonitor: networkPathMonitor,
            featureFlags: featureFlags,
            notificationCenter: notificationCenter
        ))
    }

    func select(recommendation: Recommendation, at indexPath: IndexPath? = nil, readableSource: ReadableSource = .app) {
        var destination: ContentOpen.Destination = .internal
        let item = recommendation.item

        if let slug = recommendation.collection?.slug ?? recommendation.item.collectionSlug, featureFlags.isAssigned(flag: .nativeCollections) {
            selectedReadableType = .collection(CollectionViewModel(
                slug: slug,
                source: source,
                tracker: tracker,
                user: user,
                store: store,
                networkPathMonitor: networkPathMonitor,
                userDefaults: userDefaults,
                featureFlags: featureFlags,
                notificationCenter: notificationCenter,
                readableSource: readableSource
            ))
        } else {
            let viewModel = RecommendationViewModel(
                recommendation: recommendation,
                source: source,
                tracker: tracker.childTracker(hosting: .articleView.screen),
                pasteboard: UIPasteboard.general,
                user: user,
                userDefaults: userDefaults,
                readableSource: readableSource
            )

            if item.shouldOpenInWebView(override: featureFlags.shouldDisableReader) {
                selectedReadableType = .webViewRecommendation(viewModel)
                destination = .external
            } else {
                selectedReadableType = .recommendation(viewModel)
            }
        }

        guard
            let slate = recommendation.slate,
            let slateLineup = slate.slateLineup
        else {
            Log.capture(message: "Selected recommendation without an associated slate and slatelineup, not logging analytics")
            return
        }

        let givenURL = item.givenURL
        trackSlateArticleOpen(
            url: givenURL,
            positionInList: indexPath?.item,
            slateIndex: indexPath?.section,
            slate: slate,
            slateLineup: slateLineup,
            destination: destination,
            recommendationId: recommendation.analyticsID,
            source: readableSource
        )
    }

    private func trackSlateArticleOpen(
        url: String,
        positionInList: Int?,
        slateIndex: Int?,
        slate: Slate,
        slateLineup: SlateLineup,
        destination: ContentOpen.Destination,
        recommendationId: String,
        source: ReadableSource
    ) {
        switch source {
        case .app:
            tracker.track(event: Events.Home.SlateArticleContentOpen(
                url: url,
                positionInList: positionInList,
                slateId: slate.remoteID,
                slateRequestId: slate.requestID,
                slateExperimentId: slate.experimentID,
                slateIndex: slateIndex,
                slateLineupId: slateLineup.remoteID,
                slateLineupRequestId: slateLineup.requestID,
                slateLineupExperimentId: slateLineup.experimentID,
                recommendationId: recommendationId,
                destination: destination
            ))
        case .widget:
            tracker.track(event: Events.Widgets.SlateArticleContentOpen(
                url: url,
                recommendationId: recommendationId,
                destination: destination
            ))
        }
    }

    func select(savedItem: SavedItem, at indexPath: IndexPath? = nil, readableSource: ReadableSource = .app) {
        if let slug = savedItem.item?.collection?.slug ?? savedItem.item?.collectionSlug, featureFlags.isAssigned(flag: .nativeCollections) {
            selectedReadableType = .collection(CollectionViewModel(
                slug: slug,
                source: source,
                tracker: tracker,
                user: user,
                store: store,
                networkPathMonitor: networkPathMonitor,
                userDefaults: userDefaults,
                featureFlags: featureFlags,
                notificationCenter: notificationCenter,
                readableSource: readableSource
            ))
        } else {
            let viewModel = SavedItemViewModel(
                item: savedItem,
                source: source,
                tracker: tracker.childTracker(hosting: .articleView.screen),
                pasteboard: UIPasteboard.general,
                user: user,
                store: store,
                networkPathMonitor: networkPathMonitor,
                userDefaults: userDefaults,
                notificationCenter: notificationCenter,
                readableSource: readableSource,
                featureFlagService: featureFlags
            )

            if let item = savedItem.item, item.shouldOpenInWebView(override: featureFlags.shouldDisableReader) {
                selectedReadableType = .webViewSavedItem(viewModel)
            } else {
                selectedReadableType = .savedItem(viewModel)
            }
        }
        trackRecentSavesOpen(url: savedItem.url, positionInList: indexPath?.item, source: readableSource)
    }

    private func trackRecentSavesOpen(url: String, positionInList: Int?, source: ReadableSource) {
        switch source {
        case .app:
            tracker.track(event: Events.Home.RecentSavesCardContentOpen(url: url, positionInList: positionInList))
        case .widget:
            tracker.track(event: Events.Widgets.RecentSavesCardContentOpen(url: url))
        }
    }
}

// MARK: - Section Headers
extension HomeViewModel {
    func sectionHeaderViewModel(for section: Section) -> SectionHeaderView.Model? {
        switch section {
        case .recentSaves:
            return .init(
                name: Localization.recentSaves,
                buttonTitle: Localization.seeAll,
                buttonImage: UIImage(asset: .chevronRight)
            ) { [weak self] in
                self?.tappedSeeAll = .saves
            }
        case .slateHero(let objectID):
            guard let slate = source.viewObject(id: objectID) as? Slate else {
                return nil
            }

            return .init(
                name: slate.name ?? "",
                buttonTitle: Localization.seeAll,
                buttonImage: UIImage(asset: .chevronRight)
            ) { [weak self] in
                self?.select(slate: slate)
            }
        case .loading, .slateCarousel, .offline:
            return nil
        }
    }
}

// MARK: - Loading Section
extension HomeViewModel {
    static func loadingSnapshot() -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections([.loading])
        snapshot.appendItems([.loading], toSection: .loading)
        return snapshot
    }
}

// MARK: - Recent Saves Model & Actions
extension HomeViewModel {
    func numberOfRecentSavesItem() -> Int {
        return recentSavesCount
    }

    func recentSavesViewModel(
        for objectID: NSManagedObjectID,
        at indexPath: IndexPath
    ) -> RecentSavesItemCell.Model? {
        guard let savedItem = source.viewObject(id: objectID) as? SavedItem else {
            return nil
        }

        let favoriteAction: ItemAction
        if savedItem.isFavorite {
            favoriteAction = .unfavorite { [weak self] _ in
                self?.source.unfavorite(item: savedItem)
            }
        } else {
            favoriteAction = .favorite { [weak self] _ in
                self?.source.favorite(item: savedItem)
            }
        }

        return RecentSavesItemCell.Model(
            item: savedItem,
            favoriteAction: favoriteAction,
            overflowActions: [
                .share { [weak self] sender in
                    self?.share(savedItem, at: indexPath, with: sender)
                },
                .archive { [weak self] _ in
                    self?.archive(savedItem, at: indexPath)
                },
                .delete { [weak self] _ in
                    self?.confirmDelete(item: savedItem, indexPath: indexPath)
                }
            ]
        )
    }

    private func confirmDelete(item: SavedItem, indexPath: IndexPath) {
        presentedAlert = PocketAlert(
            title: Localization.areYouSureYouWantToDeleteThisItem,
            message: nil,
            preferredStyle: .alert,
            actions: [
                UIAlertAction(title: Localization.no, style: .default) { [weak self] _ in
                    self?.presentedAlert = nil
                },
                UIAlertAction(title: Localization.yes, style: .destructive) { [weak self] _ in
                    self?.presentedAlert = nil
                    self?.delete(item: item, indexPath: indexPath)
                }
            ],
            preferredAction: nil
        )
    }

    private func delete(item: SavedItem, indexPath: IndexPath) {
        presentedAlert = nil
        tracker.track(event: Events.Home.RecentSavesCardDelete(url: item.url, positionInList: indexPath.item))
        source.delete(item: item)
    }
}

// MARK: - Slate Model
extension HomeViewModel {
    func slateModel(for objectID: NSManagedObjectID) -> Slate? {
        return source.viewObject(id: objectID) as? Slate
    }
}

// MARK: Recommendation View Model & Actions
extension HomeViewModel {
    func numberOfCarouselItemsForSlate(with id: NSManagedObjectID) -> Int {
        let count = (source.viewObject(id: id) as? Slate)?
            .recommendations?.count ?? 0

        return max(0, count - 1)
    }

    func recommendationHeroViewModel(
        for objectID: NSManagedObjectID? = nil,
        at indexPath: IndexPath? = nil
    ) -> HomeRecommendationCellViewModel? {
        guard let objectID = objectID, let recommendation = source.viewObject(id: objectID) as? Recommendation else {
            return nil
        }

        return HomeRecommendationCellViewModel(
            recommendation: recommendation,
            overflowActions: overflowActions(for: recommendation, at: indexPath),
            primaryAction: primaryAction(for: recommendation, at: indexPath)
        )
    }

    func recommendationCarouselViewModel(
        for objectID: NSManagedObjectID,
        at indexPath: IndexPath
    ) -> RecommendationCarouselCell.Model? {
        recommendationHeroViewModel(for: objectID, at: indexPath)
            .flatMap(RecommendationCarouselCell.Model.init)
    }

    private func overflowActions(for recommendation: Recommendation, at indexPath: IndexPath?) -> [ItemAction] {
        guard let indexPath = indexPath else {
            return []
        }

        return [
            .share { [weak self] sender in
                self?.share(recommendation, at: indexPath, with: sender)
            },
            .report { [weak self] _ in
                self?.report(recommendation, at: indexPath)
            }
        ]
    }

    private func primaryAction(for recommendation: Recommendation, at indexPath: IndexPath?) -> ItemAction? {
        guard let indexPath = indexPath else {
            return nil
        }

        return .recommendationPrimary { [weak self] _ in
            let isSaved = recommendation.item.savedItem != nil
            && recommendation.item.savedItem?.isArchived == false

            if isSaved {
                self?.archive(recommendation, at: indexPath)
            } else {
                self?.save(recommendation, at: indexPath)
            }
        }
    }

    private func report(_ recommendation: Recommendation, at indexPath: IndexPath) {
        selectedRecommendationToReport = recommendation
    }

    private func share(_ recommendation: Recommendation, at indexPath: IndexPath, with sender: Any?) {
        // This view model is used within the context of a view that is presented within Saves
        self.sharedActivity = PocketItemActivity.fromHome(url: recommendation.item.bestURL, sender: sender)
        let item = recommendation.item
        guard
            let slate = recommendation.slate,
            let slateLineup = slate.slateLineup
        else {
            Log.capture(message: "Shared recommendation without slate and slatelineup, not logging analytics")
            return
        }

        let givenURL = item.givenURL
        tracker.track(event: Events.Home.SlateArticleShare(url: givenURL, positionInList: indexPath.item, slateId: slate.remoteID, slateRequestId: slate.requestID, slateExperimentId: slate.experimentID, slateIndex: indexPath.section, slateLineupId: slateLineup.remoteID, slateLineupRequestId: slateLineup.requestID, slateLineupExperimentId: slateLineup.experimentID, recommendationId: recommendation.analyticsID))
    }

    private func share(_ savedItem: SavedItem, at indexPath: IndexPath, with sender: Any?) {
        // This view model is used within the context of a view that is presented within Home, but
        // within the context of "Recent Saves"
        self.sharedActivity = PocketItemActivity.fromSaves(url: savedItem.url, sender: sender)
        tracker.track(event: Events.Home.RecentSavesCardShare(url: savedItem.url, positionInList: indexPath.item))
    }

    private func save(_ recommendation: Recommendation, at indexPath: IndexPath) {
        source.save(recommendation: recommendation)
        let item = recommendation.item
        guard
            let slate = recommendation.slate,
            let slateLineup = slate.slateLineup
        else {
            Log.capture(message: "Saved recommendation slate and slatelineup, not logging analytics")
            return
        }

        let givenURL = item.givenURL
        tracker.track(event: Events.Home.SlateArticleSave(url: givenURL, positionInList: indexPath.item, slateId: slate.remoteID, slateRequestId: slate.requestID, slateExperimentId: slate.experimentID, slateIndex: indexPath.section, slateLineupId: slateLineup.remoteID, slateLineupRequestId: slateLineup.requestID, slateLineupExperimentId: slateLineup.experimentID, recommendationId: recommendation.analyticsID))
    }

    private func archive(_ recommendation: Recommendation, at indexPath: IndexPath) {
        source.archive(recommendation: recommendation)
        let item = recommendation.item
        guard
            let slate = recommendation.slate,
            let slateLineup = slate.slateLineup
        else {
            Log.capture(message: "Archived recommendation without slate and slatelineup, not logging analytics")
            return
        }

        let givenURL = item.givenURL
        tracker.track(event: Events.Home.SlateArticleArchive(url: givenURL, positionInList: indexPath.item, slateId: slate.remoteID, slateRequestId: slate.requestID, slateExperimentId: slate.experimentID, slateIndex: indexPath.section, slateLineupId: slateLineup.remoteID, slateLineupRequestId: slateLineup.requestID, slateLineupExperimentId: slateLineup.experimentID, recommendationId: recommendation.analyticsID))
    }

    private func archive(_ savedItem: SavedItem, at indexPath: IndexPath) {
        self.source.archive(item: savedItem)
        tracker.track(event: Events.Home.RecentSavesCardArchive(url: savedItem.url, positionInList: indexPath.item))
    }
}

// MARK: - Cell Lifecycle
extension HomeViewModel {
    func willDisplay(_ cell: HomeViewModel.Cell, at indexPath: IndexPath) {
        switch cell {
        case .loading, .offline:
            return
        case .recentSaves(let objectID):
            guard let savedItem = source.viewObject(id: objectID) as? SavedItem else {
                Log.breadcrumb(category: "home", level: .debug, message: "Could not turn recent save into Saved Item from objectID: \(String(describing: objectID))")
                Log.capture(message: "SavedItem is null on willDisplay Home Recent Saves")
                return
            }
            tracker.track(event: Events.Home.RecentSavesCardImpression(url: savedItem.url, positionInList: indexPath.item))
            return
        case .recommendationHero(let objectID), .recommendationCarousel(let objectID):
            guard let recommendation = source.viewObject(id: objectID) as? Recommendation else {
                Log.breadcrumb(category: "home", level: .debug, message: "Could not turn recomendation into Recommendation from objectID: \(String(describing: objectID))")
                Log.capture(message: "Recommendation is null on willDisplay Home Recommendation")
                return
            }
            let item = recommendation.item
            guard
                let slate = recommendation.slate,
                let slateLineup = slate.slateLineup
            else {
                Log.breadcrumb(category: "home", level: .debug, message: "Tried to display recommendation without slate and slatelineup, not logging analytics")
                return
            }

            let givenURL = item.givenURL
            tracker.track(event: Events.Home.SlateArticleImpression(url: givenURL, positionInList: indexPath.item, slateId: slate.remoteID, slateRequestId: slate.requestID, slateExperimentId: slate.experimentID, slateIndex: indexPath.section, slateLineupId: slateLineup.remoteID, slateLineupRequestId: slateLineup.requestID, slateLineupExperimentId: slateLineup.experimentID, recommendationId: recommendation.analyticsID))
        }
    }
}

extension HomeViewModel {
    enum Section: Hashable {
        case loading
        case recentSaves
        case slateHero(NSManagedObjectID)
        case slateCarousel(NSManagedObjectID)
        case offline
    }

    enum Cell: Hashable {
        case loading
        case recentSaves(NSManagedObjectID)
        case recommendationHero(NSManagedObjectID)
        case recommendationCarousel(NSManagedObjectID)
        case offline
    }
}

extension HomeViewModel {
    func clearRecommendationToReport() {
        tappedSeeAll?.clearRecommendationToReport()
        selectedRecommendationToReport = nil
    }

    func clearPresentedWebReaderURL() {
        tappedSeeAll?.clearPresentedWebReaderURL()
    }

    func clearSharedActivity() {
        tappedSeeAll?.clearSharedActivity()
        sharedActivity = nil
    }

    func clearIsPresentingReaderSettings() {
        selectedReadableType?.clearIsPresentingReaderSettings()
        tappedSeeAll?.clearIsPresentingReaderSettings()
    }

    func clearSelectedItem() {
        tappedSeeAll?.clearSelectedItem()
        selectedReadableType = nil
    }

    func clearTappedSeeAll() {
        tappedSeeAll = nil
    }
}

extension HomeViewModel {
    func activityItemsForSelectedItem(url: URL) -> [UIActivity] {
        switch selectedReadableType {
        case .recommendation(let viewModel),
                .webViewRecommendation(let viewModel):
            return viewModel.webViewActivityItems(url: url)
        case .savedItem(let viewModel),
                .webViewSavedItem(let viewModel):
            return viewModel.webViewActivityItems(url: url)
        case .collection, .none:
            return []
        }
    }
}

extension HomeViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        var newSnapshot = buildSnapshot()

        if controller == self.recentSavesController {
            let reloadedItemIdentifiers: [Cell] = snapshot.reloadedItemIdentifiers.compactMap({ .recentSaves($0 as! NSManagedObjectID) })
            let reconfiguredItemdIdentifiers: [Cell] = snapshot.reconfiguredItemIdentifiers.compactMap({ .recentSaves($0 as! NSManagedObjectID) })
            newSnapshot.reloadItems(reloadedItemIdentifiers)
            newSnapshot.reconfigureItems(reconfiguredItemdIdentifiers)
            updateRecentSavesWidget()
        }

        if isOffline {
            // If we are offline don't try and do anything with Slates, and let the snapshot show the offline
            setRecommendationsWidgetOffline()
            self.snapshot = newSnapshot
            return
        }

        if controller == self.recomendationsController {
            let existingItemIdentifiers = newSnapshot.itemIdentifiers

            // Gather all variations a recomendation could exist in for reloaded identifiers
            var reloadedItemIdentifiers: [Cell] = snapshot.reloadedItemIdentifiers.compactMap({ .recommendationHero($0 as! NSManagedObjectID) })
            reloadedItemIdentifiers.append(contentsOf: snapshot.reloadedItemIdentifiers.compactMap({ .recommendationCarousel($0 as! NSManagedObjectID) }))
            // Filter to just the ones that exist in our snapshot
            reloadedItemIdentifiers = reloadedItemIdentifiers.filter({ existingItemIdentifiers.contains($0) })
            // Tell the new snapshot to reload just the ones that exist
            newSnapshot.reloadItems(reloadedItemIdentifiers)

            // Gather all variations a recomendation could exist in for reconfigured identifiers
            var reconfiguredItemIdentifiers: [Cell] = snapshot.reconfiguredItemIdentifiers.compactMap({ .recommendationHero($0 as! NSManagedObjectID) })
            reconfiguredItemIdentifiers.append(contentsOf: snapshot.reconfiguredItemIdentifiers.compactMap({ .recommendationCarousel($0 as! NSManagedObjectID) }))
            // Filter to just the ones that exist in our snapshot
            reconfiguredItemIdentifiers = reconfiguredItemIdentifiers.filter({ existingItemIdentifiers.contains($0) })
            // Tell the new snapshot to reconfigure just the ones that exist
            newSnapshot.reconfigureItems(reconfiguredItemIdentifiers)
            updateRecommendationsWidget()
        }

        self.snapshot = newSnapshot
    }
}

// MARK: recent saves widget
private extension HomeViewModel {
    func updateRecentSavesWidget() {
        guard let items = recentSavesController.fetchedObjects else {
            recentSavesWidgetUpdateService.update([])
            return
        }
        // because we might still end up with more items, slice the first n elements anyway.
        recentSavesWidgetUpdateService.update(Array(items.prefix(SyncConstants.Home.recentSaves)))
    }
}

// MARK: Recommendations - Editor's Picks widget
private extension HomeViewModel {
    func updateRecommendationsWidget() {
        guard let sections = recomendationsController.sections, !sections.isEmpty else {
            setRecommendationsWidgetOffline()
            return
        }

        let topics = sections.reduce(into: [String: [Recommendation]]()) {
            if let recommendations = $1.objects as? [Recommendation], let name = recommendations.first?.slate?.name {
                $0[name] = recommendations
            }
        }
        recommendationsWidgetUpdateService.update(topics)
    }

    func setRecommendationsWidgetOffline() {
        recommendationsWidgetUpdateService.update([:])
    }
}
