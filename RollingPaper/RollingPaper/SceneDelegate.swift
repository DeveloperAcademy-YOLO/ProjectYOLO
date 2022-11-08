//
//  SceneDelegate.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit
import FirebaseDynamicLinks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let splitVC = SplitViewController(style: .doubleColumn)
        window.rootViewController = splitVC
        window.makeKeyAndVisible()
        window.overrideUserInterfaceStyle = .light
        self.window = window
        print("Scene Delegate Come")
        
        for userActivity in connectionOptions.userActivities {
            if let incomingURL = userActivity.webpageURL {
                let linkHandled = DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { dynamicLink, error in
                    guard
                        let dynamicLink = dynamicLink,
                        error == nil else { return }
                    self.handleDynamicLink(dynamicLink: dynamicLink)
                }
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard
            let url = URLContexts.first?.url,
            let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) else { return }
        handleDynamicLink(dynamicLink: dynamicLink)
    }

    func sceneDidDisconnect(_ scene: UIScene) {

    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let incomingURL = userActivity.webpageURL else { return }
        let linkHandled = DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { dynamicLink, error in
            guard
                let dynamicLink = dynamicLink,
                error == nil else { return }
            self.handleDynamicLink(dynamicLink: dynamicLink)
        }
    }
    
    private func handleURL(url: URL) {
        if DynamicLinks.dynamicLinks().shouldHandleDynamicLink(fromCustomSchemeURL: url) {
            guard let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) else { return }
            handleDynamicLink(dynamicLink: dynamicLink)
        } else {
            DynamicLinks.dynamicLinks().dynamicLink(fromUniversalLink: url, completion: { [weak self] dynamicLink, error in
                guard
                    let dynamicLink = dynamicLink,
                    error == nil else { return }
                self?.handleDynamicLink(dynamicLink: dynamicLink)
            })
        }
    }
    
    private func handleDynamicLink(dynamicLink: DynamicLink) {
        guard
            let urlString = dynamicLink.url?.absoluteString,
            let components = URLComponents(string: urlString),
            let items = components.queryItems,
            let paperId = items.first(where: {$0.name == "paperId"})?.value,
            let routeString = items.first(where: {$0.name == "route"})?.value else {
            print("handleDynamicLink Fails")
            return
        }
        NotificationCenter.default.post(name: .deeplink, object: nil, userInfo: ["paperId": paperId, "route": routeString])
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UserDefaults.standard.setValue(0, forKey: "currentBadgeCount")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
