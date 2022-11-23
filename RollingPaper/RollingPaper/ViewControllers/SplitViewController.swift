//
//  ViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit
import Combine
import CombineCocoa

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    private let splitViewManager = SplitViewManager.shared
    private let input: PassthroughSubject<SplitViewManager.Input, Never> = .init()
    private var currentSecondaryView = "새 페이퍼"
    private var sidebarViewController: UINavigationController!
    private var paperTemplateSelectViewController: UINavigationController!
    private var paperStorageViewController: UINavigationController!
    private var giftStorageViewController: UINavigationController!
    private var appSettingViewController: UINavigationController!
    private var settingScreenViewController: UINavigationController!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerChangeViewNC()
        setupSplitView()
        splitViewManager.transform(input: input.eraseToAnyPublisher())
    }
    
    private func registerChangeViewNC() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSecondaryView(notification:)),
            name: .viewChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSecondaryViewFromSidebar(notification:)),
            name: .viewChangeFromSidebar,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeFromDeeplink),
            name: .deeplink,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(initializeNavigationStack(notification:)),
            name: .viewInit,
            object: nil)
    }
    
    private func setupSplitView() {
        delegate = self
        self.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
        self.presentsWithGesture = true
        self.loadViewControllers()
        self.preferredPrimaryColumnWidthFraction = 0.25
    }
    
    private func loadViewControllers() {
        sidebarViewController = UINavigationController(rootViewController: SidebarViewController())
        paperTemplateSelectViewController = UINavigationController(rootViewController: PaperTemplateSelectViewController())
        paperStorageViewController = UINavigationController(rootViewController: PaperStorageViewController())
        giftStorageViewController = UINavigationController(rootViewController: GiftStorageViewController())
        appSettingViewController = UINavigationController(rootViewController: AppSettingViewController())
        if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
            settingScreenViewController = UINavigationController(rootViewController: SettingScreenViewController())
        } else {
            settingScreenViewController = UINavigationController(rootViewController: SignInViewController())
        }
        self.viewControllers = [sidebarViewController, paperTemplateSelectViewController]
    }
    
    @objc private func changeFromDeeplink(notification: Notification) {
        guard
            let paperId = notification.userInfo?["paperId"] as? String,
            let routeString = notification.userInfo?["route"] as? String,
            let route = PaperShareRoute(rawValue: routeString) else { return }
        navigateToFlow(paperId: paperId, route: route)
    }
    
    private func navigateToFlow(paperId: String, route: PaperShareRoute) {
        if route == .write {
            if let currentNavVC = viewControllers[1] as? UINavigationController {
                currentNavVC.popToRootViewController(true) {
                    self.setViewController(self.paperStorageViewController, for: .secondary)
                    if let paperVC = self.paperStorageViewController.viewControllers.first as? PaperStorageViewController {
                        let writtenVC = WrittenPaperViewController()
                        self.paperStorageViewController.pushViewController(writtenVC, animated: true) {
                            LocalDatabaseFileManager.shared.fetchPaper(paperId: paperId)
                            FirestoreManager.shared.fetchPaper(paperId: paperId)
                        }
                    }
                }
            }
        } else {
            // Gift Storage -> Gift Paper
            if let currentNavVC = viewControllers[1] as? UINavigationController {
                currentNavVC.popToRootViewController(true) {
                    self.setViewController(self.giftStorageViewController, for: .secondary)
                    if let giftStorageVC = self.giftStorageViewController.viewControllers.first as? GiftStorageViewController {
                        let giftVC = WrittenPaperViewController()
                        self.giftStorageViewController.pushViewController(giftVC, animated: true) {
                            LocalDatabaseFileManager.shared.fetchPaper(paperId: paperId)
                            FirestoreManager.shared.fetchPaper(paperId: paperId)
                        }
                    }
                }
            }
        }
    }
    
    @objc private func changeSecondaryView(notification: Notification) {
        guard let object = notification.userInfo?[NotificationViewKey.view] as? String else { return }
        switch object {
        case "새 페이퍼":
            setViewController(paperTemplateSelectViewController, for: .secondary)
            currentSecondaryView = "새 페이퍼"
        case "보관함":
            if currentSecondaryView == "새 페이퍼" {
                self.paperTemplateSelectViewController.popToRootViewController(animated: false)
                self.paperStorageViewController.pushViewController(WrittenPaperViewController(), animated: false)
                setViewController(paperStorageViewController, for: .secondary)
            } else {
                self.paperStorageViewController.popToRootViewController(animated: false)
            }
            currentSecondaryView = "보관함"
        case "선물 상자":
            setViewController(giftStorageViewController, for: .secondary)
            currentSecondaryView = "선물 상자"
        case "설정":
            setViewController(appSettingViewController, for:.secondary)
            currentSecondaryView = "설정"
        case "프로필":
            if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
                self.settingScreenViewController.setViewControllers([SettingScreenViewController()], animated: false)
            } else {
                self.settingScreenViewController.setViewControllers([SignInViewController()], animated: false)
            }
            currentSecondaryView = "설정"
        default:
            break
        }
        self.currentSecondaryView = object
    }
    
    @objc private func changeSecondaryViewFromSidebar(notification: Notification) {
        guard let object = notification.userInfo?[NotificationViewKey.view] as? String else { return }
        if self.currentSecondaryView == object {
            return
        }
        switch object {
        case "새 페이퍼":
            setViewController(paperTemplateSelectViewController, for: .secondary)
            currentSecondaryView = "새 페이퍼"
        case "보관함":
            setViewController(paperStorageViewController, for: .secondary)
            currentSecondaryView = "보관함"
        case "선물 상자":
            setViewController(giftStorageViewController, for: .secondary)
            currentSecondaryView = "선물 상자"
        case "설정":
            setViewController(appSettingViewController, for: .secondary)
            currentSecondaryView = "설정"
        case "프로필":
            if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
                self.appSettingViewController.popToRootViewController(animated: false)
                self.appSettingViewController.pushViewController(SettingScreenViewController(), animated: false)
                if currentSecondaryView != "설정" {
                    setViewController(appSettingViewController, for: .secondary)
                }
            } else {
                self.appSettingViewController.popToRootViewController(animated: false)
                self.appSettingViewController.pushViewController(SignInViewController(), animated: false)
                if currentSecondaryView != "설정" {
                    setViewController(appSettingViewController, for: .secondary)
                }
            }
            currentSecondaryView = "설정"
        default:
            break
        }
        self.currentSecondaryView = object
    }
    
    @objc private func initializeNavigationStack(notification: Notification) {
        guard let object = notification.userInfo?[NotificationViewKey.view] as? String else { return }
        switch object {
        case "signOut":
            paperTemplateSelectViewController.popToRootViewController(animated: false)
            paperStorageViewController.popToRootViewController(animated: false)
            // TODO: GiftboxViewController() 생성
            // settingScreenViewController = UINavigationController(rootViewController: )
        // case "signIn":
        default:
            break
        }
    }
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        if displayMode.rawValue == 1 {
            input.send(.viewIsClosed)
        } else {
            input.send(.viewIsOpened)
        }
    }
}
