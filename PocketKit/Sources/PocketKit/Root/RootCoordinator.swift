import UIKit
import Sync
import SwiftUI
import Combine
import SafariServices
import Analytics


class RootCoordinator {
    private var window: UIWindow?

    private let source: Source
    private let tracker: Tracker

    private let model: RootViewModel
    private var subscriptions: [AnyCancellable] = []

    private var main: MainCoordinator?
    private var signIn: SignInCoordinator?

    init(
        model: RootViewModel,
        source: Source,
        tracker: Tracker
    ) {
        self.model = model
        self.source = source
        self.tracker = tracker
    }

    func setup(scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        window = UIWindow(windowScene: windowScene)

        model.$state.sink { [weak self] state in
            if Thread.isMainThread {
                self?.handle(state: state)
            } else {
                DispatchQueue.main.async {
                    self?.handle(state: state)
                }
            }
        }.store(in: &subscriptions)

        window?.makeKeyAndVisible()
    }

    private func handle(state: RootViewModel.State) {
        switch state {
        case .main(let model):
            signIn = nil
            main = MainCoordinator(model: model, source: source, tracker: tracker)

            transition(to: main?.viewController) { [main] in
                self.source.refresh()
                main?.showList()
            }
        case .signIn(let model):
            main = nil
            signIn = SignInCoordinator(model: model)
            transition(to: signIn?.viewController)
        }
    }

    private func transition(to rootViewController: UIViewController?, animation: (() -> Void)? = nil) {
        UIView.transition(
            with: window!,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                self.window?.rootViewController = rootViewController
                animation?()
            },
            completion: nil
        )
    }
}