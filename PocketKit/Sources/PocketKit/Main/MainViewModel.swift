import Combine
import Network
import Sync
import Foundation
import BackgroundTasks
import UIKit
import Textile
import Localization

@MainActor
class MainViewModel: ObservableObject {
    let home: HomeViewModel
    let saves: SavesContainerViewModel
    let account: AccountViewModel
    let source: Source

    @Published var selectedSection: AppSection = .home

    @Published var bannerViewModel: PasteBoardModifier.PasteBoardData?

    @Published var showBanner: Bool = false

    private var subscriptions: Set<AnyCancellable> = []
    private let userDefaults: UserDefaults

    convenience init() {
        self.init(
            saves: SavesContainerViewModel(
                searchList: SearchViewModel(
                    networkPathMonitor: NWPathMonitor(),
                    user: Services.shared.user,
                    userDefaults: Services.shared.userDefaults,
                    source: Services.shared.source,
                    tracker: Services.shared.tracker.childTracker(hosting: .saves.search),
                    store: Services.shared.subscriptionStore
                ) { source in
                    PremiumUpgradeViewModel(
                        store: Services.shared.subscriptionStore,
                        tracker: Services.shared.tracker,
                        source: source,
                        networkPathMonitor: NWPathMonitor()
                    )
                },
                savedItemsList: SavedItemsListViewModel(
                    source: Services.shared.source,
                    tracker: Services.shared.tracker.childTracker(hosting: .saves.saves),
                    viewType: .saves,
                    listOptions: .saved(userDefaults: Services.shared.userDefaults),
                    notificationCenter: .default,
                    user: Services.shared.user,
                    store: Services.shared.subscriptionStore,
                    refreshCoordinator: Services.shared.savesRefreshCoordinator,
                    networkPathMonitor: NWPathMonitor(),
                    userDefaults: Services.shared.userDefaults
                ),
                archivedItemsList: SavedItemsListViewModel(
                    source: Services.shared.source,
                    tracker: Services.shared.tracker.childTracker(hosting: .saves.archive),
                    viewType: .archive,
                    listOptions: .archived(userDefaults: Services.shared.userDefaults),
                    notificationCenter: .default,
                    user: Services.shared.user,
                    store: Services.shared.subscriptionStore,
                    refreshCoordinator: Services.shared.archiveRefreshCoordinator,
                    networkPathMonitor: NWPathMonitor(),
                    userDefaults: Services.shared.userDefaults
                )
            ),
            home: HomeViewModel(
                source: Services.shared.source,
                tracker: Services.shared.tracker.childTracker(hosting: .home.screen),
                networkPathMonitor: NWPathMonitor(),
                homeRefreshCoordinator: Services.shared.homeRefreshCoordinator,
                user: Services.shared.user,
                store: Services.shared.subscriptionStore,
                userDefaults: Services.shared.userDefaults
            ),
            account: AccountViewModel(
                appSession: Services.shared.appSession,
                user: Services.shared.user,
                tracker: Services.shared.tracker,
                userDefaults: Services.shared.userDefaults,
                userManagementService: Services.shared.userManagementService,
                notificationCenter: .default,
                networkPathMonitor: NWPathMonitor(),
                restoreSubscription: {
                    try await Services.shared.subscriptionStore.restoreSubscription()
                },
                premiumUpgradeViewModelFactory: { source in
                    PremiumUpgradeViewModel(
                        store: Services.shared.subscriptionStore,
                        tracker: Services.shared.tracker,
                        source: source,
                        networkPathMonitor: NWPathMonitor()
                    )
                },
                premiumStatusViewModelFactory: {
                    PremiumStatusViewModel(service: PocketSubscriptionInfoService(client: Services.shared.v3Client), tracker: Services.shared.tracker)
                }
            ),
            source: Services.shared.source,
            userDefaults: Services.shared.userDefaults
        )
    }

    init(
        saves: SavesContainerViewModel,
        home: HomeViewModel,
        account: AccountViewModel,
        source: Source,
        userDefaults: UserDefaults
    ) {
        self.saves = saves
        self.home = home
        self.account = account
        self.source = source
        self.userDefaults = userDefaults

        self.loadStartingAppSection()
        self.clearStartingAppSection()

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).delay(for: 0.5, scheduler: RunLoop.main).sink { [weak self] _ in
            self?.showSaveFromClipboardBanner()
        }.store(in: &subscriptions)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).sink { [weak self] _ in
            self?.bannerViewModel = nil
            self?.saveStartingAppSection()
        }.store(in: &subscriptions)
    }

    enum AppSection: CaseIterable, Identifiable, Hashable {
        static var allCases: [MainViewModel.AppSection] {
            return [.home, .saves, .account]
        }

        case home
        case saves
        case account

        init(from rawValue: String?) {
            switch rawValue {
            case AppSection.saves.id:
                self = .saves
            case AppSection.account.id:
                self = .account
            default:
                self = .home
            }
        }

        var id: String {
            switch self {
            case .home:
                return "home"
            case .saves:
                return "saves"
            case .account:
                return "account"
            }
        }
    }

    func clearRecommendationToReport() {
        home.clearRecommendationToReport()
    }

    func clearSharedActivity() {
        home.clearSharedActivity()
        saves.clearSharedActivity()
    }

    func clearIsPresentingReaderSettings() {
        home.clearIsPresentingReaderSettings()
        saves.clearIsPresentingReaderSettings()
    }

    func clearPresentedWebReaderURL() {
        home.clearPresentedWebReaderURL()
        saves.clearPresentedWebReaderURL()
    }

    func selectSavesTab() {
        self.selectedSection = .saves
    }

    func showSaveFromClipboardBanner() {
        if UIPasteboard.general.hasURLs {
            bannerViewModel = PasteBoardModifier.PasteBoardData(
                title: Localization.addCopiedURLToYourSaves,
                action: PasteBoardModifier.PasteBoardData.PasteBoardAction(
                    text: Localization.saves,
                    action: { [weak self] url in
                        self?.handleBannerPrimaryAction(url: url)
                    }, dismiss: { [weak self] in
                        DispatchQueue.main.async { [weak self] in
                            self?.bannerViewModel = nil
                        }
                    }
                )
            )
        }
    }

    private func handleBannerPrimaryAction(url: URL?) {
        DispatchQueue.main.async { [weak self] in
            self?.bannerViewModel = nil
        }

        guard let url = url else { return }
        source.save(url: url)
    }

    // MARK: Tab Restoration

    private func loadStartingAppSection() {
        let selectedSectionID = userDefaults.string(forKey: UserDefaults.Key.startingAppSection)
        selectedSection = AppSection(from: selectedSectionID)
    }

    private func saveStartingAppSection() {
        userDefaults.setValue(selectedSection.id, forKey: UserDefaults.Key.startingAppSection)
    }

    private func clearStartingAppSection() {
        userDefaults.removeObject(forKey: UserDefaults.Key.startingAppSection)
    }
}
