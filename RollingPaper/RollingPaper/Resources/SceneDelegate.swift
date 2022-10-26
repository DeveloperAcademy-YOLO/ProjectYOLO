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
        self.window = window
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        } else {
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlToOpen = URLContexts.first?.url else { return }
        handleURL(url: urlToOpen)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let incomingURL = userActivity.webpageURL else { return }
        handleURL(url: incomingURL)
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
            let routeString = items.first(where: {$0.name == "route"})?.value,
            let route = PaperShareRoute(rawValue: routeString) else {
            print("handleDynamicLink Fails")
            return
        }
        navigateToFlow(paperId: paperId, route: route)
    }
    
    private func navigateToFlow(paperId: String, route: PaperShareRoute) {
        if route == .write {
            guard let splitVC = window?.rootViewController as? SplitViewController else { return }
            NotificationCenter.default.post(name: .viewChange, object: nil, userInfo: [NotificationViewKey.view : "페이퍼 보관함"])
//            guard
//                let paperNavVC = splitVC.viewControllers[1] as? UINavigationController,
//                let paperVC = paperNavVC.viewControllers.last as? PaperStorageViewController else { return }
//            paperNavVC.pushViewController(WrittenPaperViewController(), animated: true) {
//                paperVC.setSelectedPaper(paperId: paperId)
//                print("push after: \(paperNavVC.viewControllers)")
//            }
        }
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
