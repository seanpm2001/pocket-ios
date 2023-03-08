// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Sails
import StoreKitTest

class PremiumTests: XCTestCase {
    var server: Application!
    var app: PocketAppElement!
    var storeSession: SKTestSession!
    var snowplowMicro = SnowplowMicro()

    override func setUp() async throws {
        continueAfterFailure = false
        storeSession = try SKTestSession(configurationFileNamed: "Test_Subscriptions")
        storeSession.resetToDefaultState()
        storeSession.clearTransactions()
        storeSession.disableDialogs = true
        app = PocketAppElement(app: XCUIApplication())
        server = Application()

        await snowplowMicro.resetSnowplowEvents()
        try server.start()
    }

    override func tearDownWithError() throws {
        try server.stop()
        storeSession.clearTransactions()
        storeSession.resetToDefaultState()
        storeSession = nil
        app.terminate()
    }

    /// Test that tapping "Go Premium" in Settings presents the Premium Upgrade view
    @MainActor func test_tapSettingsUpsellShowsUpgradeView() async {
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSettings()
    }

    @MainActor func test_tapSearchPremiumUpsellShowsUpgradeView() async {
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSearch()
    }

    /// Test that Premium Upgrade view dismisses when tapping the dismiss button
    @MainActor func test_tapDismissDismissPremiumView() async {
        // Given
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSettings()
        // When
        app.premiumUpgradeView.dismissPremiumButton.wait().tap()
        // Then
        let dismissPremiumEvent = await snowplowMicro.getFirstEvent(with: "global-nav.premium.dismiss")
        XCTAssertNotNil(dismissPremiumEvent)
        XCTAssertFalse(app.premiumUpgradeView.exists)
    }

    /// Test that monthly button tapped triggers the right event
    @MainActor func test_monthlyButtonTapped() async {
        // Given
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSettings()
        // When
        app.premiumUpgradeView.premiumUpgradeMonthlyButton.wait().tap()
        // Then
        let monthlyButtonTappedEvent = await snowplowMicro.getFirstEvent(with: "global-nav.premium.monthly")
        XCTAssertNotNil(monthlyButtonTappedEvent)
    }

    /// Test that annual button tapped triggers the right event
    @MainActor func test_annualButtonTapped() async {
        // Given
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSettings()
        // When
        app.premiumUpgradeView.premiumUpgradeAnnualButton.wait().tap()
        // Then
        let monthlyButtonTappedEvent = await snowplowMicro.getFirstEvent(with: "global-nav.premium.annual")
        XCTAssertNotNil(monthlyButtonTappedEvent)
    }

    /// Test that purchase monthly subscription succeeds
    @MainActor func test_purchaseMonthlySubscriptionSuccess() async {
        // Given
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSettings()
        // When
        try! storeSession.buyProduct(productIdentifier: "monthly.subscription.pocket")
        // Then
        let purchaseSuccessEvent = await snowplowMicro.getFirstEvent(with: "global-nav.premium.purchase.success")
        XCTAssertNotNil(purchaseSuccessEvent)

        purchaseSuccessEvent!.getUIContext()!.assertHas(type: "dialog")
    }

    /// Test that purchase annual subscription succeeds
    @MainActor func test_purchaseAnnualSubscriptionSuccess() async {
        // Given
        configureFreeUser()
        app.launch()
        await loadPremiumUpgradeViewFromSettings()
        // When
        try! storeSession.buyProduct(productIdentifier: "annual.subscription.pocket")
        // Then
        let purchaseSuccessEvent = await snowplowMicro.getFirstEvent(with: "global-nav.premium.purchase.success")
        XCTAssertNotNil(purchaseSuccessEvent)

        purchaseSuccessEvent!.getUIContext()!.assertHas(type: "dialog")
    }

    @MainActor func configureFreeUser() {
        server.routes.post("/graphql") { request, _ in
            let apiRequest = ClientAPIRequest(request)
            if apiRequest.isForSavesContent {
                return Response.freeUserSaves()
            }
            return Response.fallbackResponses(apiRequest: apiRequest)
        }
    }

    @MainActor private func loadPremiumUpgradeViewFromSettings() async {
        app.tabBar.settingsButton.wait().tap()
        XCTAssertTrue(app.settingsView.exists)

        let settingsViewEvent = await snowplowMicro.getFirstEvent(with: "global-nav.settings")
        XCTAssertNotNil(settingsViewEvent)

        let goPremiumButtonImpression = await snowplowMicro.getFirstEvent(with: "account.premium.upsell")
        XCTAssertNotNil(goPremiumButtonImpression)

        goPremiumButtonImpression!.getUIContext()!.assertHas(type: "button")

        tapSettingsPremiumUpsell()
        XCTAssertTrue(app.premiumUpgradeView.exists)

        let premiumViewShownEvent = await snowplowMicro.getFirstEvent(with: "global-nav.premium")
        XCTAssertNotNil(premiumViewShownEvent)
    }

    private func tapSettingsPremiumUpsell() {
        app.settingsView.goPremiumButton.tap()
    }

    @MainActor private func loadPremiumUpgradeViewFromSearch() async {
        app.tabBar.savesButton.wait().tap()
        app.saves.filterButton(for: "Search").wait().tap()
        app.navigationBar.buttons["All items"].wait().tap()
        XCTAssertTrue(app.searchGetPremiumEmptyView.exists)

        let goPremiumButtonImpression = await snowplowMicro.getFirstEvent(with: "global-nav.search.premium.upsell")
        XCTAssertNotNil(goPremiumButtonImpression)

        goPremiumButtonImpression!.getUIContext()!.assertHas(type: "button")

        tapSearchPremiumUpsell()
        XCTAssertTrue(app.premiumUpgradeView.exists)

        let searchUpsellEvent = await snowplowMicro.getFirstEvent(with: "global-nav.search.premium.upsell")
        XCTAssertNotNil(searchUpsellEvent)
    }

    private func tapSearchPremiumUpsell() {
        app.searchGetPremiumEmptyView.getPocketPremiumButton.tap()
    }
}