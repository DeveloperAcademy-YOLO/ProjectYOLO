//
//  AppDelegate.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/04.
//

import UIKit
import FirebaseCore
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        let window = UIWindow(frame: UIScreen.main.bounds)
        let splitVC = SplitViewController(style: .doubleColumn)
        window.makeKeyAndVisible()
        window.rootViewController = splitVC
        self.window = window
        UNUserNotificationCenter.current().delegate = self
        registerPushNotifications()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// Foreground Push Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }
    
    /// Background Push Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if
            let paperId = response.notification.request.content.userInfo["paperId"] as? String {
            print("Background Called")
            print("paperId: \(paperId)")
            navigatePaperView(paperId: paperId)
        }
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
            UIApplication.shared.applicationIconBadgeNumber = 0
            UserDefaults.standard.set(0, forKey: "currentBadgeCount")
        }
        completionHandler()
    }
    
    // Navigate to Paper View using PaperId
    private func navigatePaperView(paperId: String) {
        guard let rootVC = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController as? SplitViewController else { return }
        let paperView = PaperStorageViewController()
        let navVC = UINavigationController(rootViewController: paperView)
        rootVC.viewControllers[1] = navVC
        if paperView.isFromServer(paperId: paperId) {
            FirestoreManager.shared.fetchPaper(paperId: paperId)
        } else {
            LocalDatabaseMockManager.shared.fetchPaper(paperId: paperId)
        }
        // TODO: 사이먼 뷰로 이동
        // navVC.pushViewController(SimonView(), animated: true)
    }
    
    /// Register Push Notifctation Permission: (1). AppDelegate (2). After Real Paper activated
    func registerPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { granted, _ in
                print("Permission Granted: \(granted)")
                guard !granted else { return }
                self.getNotificationSettings()
            })
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current()
            .getNotificationSettings { [weak self] settings in
                guard settings.authorizationStatus != .authorized else { return }
                DispatchQueue.main.async {
                    self?.openSettingView()
                }
            }
    }
    
    private func openSettingView() {
        if let settingURL = URL(string: UIApplication.openSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(settingURL, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(settingURL)
            }
        }
    }
}
