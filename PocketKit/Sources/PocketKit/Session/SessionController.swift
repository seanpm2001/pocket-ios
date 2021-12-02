import Sync
import Analytics
import Foundation
import Textile


class SessionController {

    private let authClient: AuthorizationClient
    private let session: Session
    private let accessTokenStore: AccessTokenStore
    private let tracker: Tracker
    private let source: Source
    private let userDefaults: UserDefaults

    init(
        authClient: AuthorizationClient,
        session: Session,
        accessTokenStore: AccessTokenStore,
        tracker: Tracker,
        source: Source,
        userDefaults: UserDefaults
    ) {
        self.authClient = authClient
        self.session = session
        self.accessTokenStore = accessTokenStore
        self.tracker = tracker
        self.source = source
        self.userDefaults = userDefaults
    }

    var isSignedIn: Bool {
        session.userID != nil
        && session.guid != nil
        && accessTokenStore.accessToken != nil
    }

    func signOut() {
        try? accessTokenStore.delete()

        source.clear()
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        tracker.resetPersistentContexts([
            APIUserContext(consumerKey: Keys.shared.pocketApiConsumerKey)
        ])
        session.userID = nil
        session.guid = nil

        Crashlogger.clearUser()
        Textiles.clearImageCache()
    }

    func signIn(username: String, password: String) async throws {
        do {
            let guid = try await authClient.requestGUID()
            let authResponse = try await authClient.authorize(
                guid: guid,
                username: username,
                password: password
            )
            let userID = authResponse.account.userID

            session.guid = guid
            session.userID = userID
            try accessTokenStore.save(token: authResponse.accessToken)

            let user = UserContext(guid: guid, userID: userID)
            tracker.addPersistentContext(user)
            Crashlogger.setUserID(userID)
        } catch(let signInError) {
            Crashlogger.capture(error: signInError)
            throw signInError
        }
    }

    func updateSession(
        accessToken: String?,
        guid: String?,
        userID: String?
    ) {
        if let accessToken = accessToken {
            try? accessTokenStore.save(token: accessToken)
        }

        if let guid = guid {
            session.guid = guid
        }

        if let userID = userID {
            session.userID = userID
        }
    }
}
