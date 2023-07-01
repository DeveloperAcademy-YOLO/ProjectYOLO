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
    private var currentSecondaryView = SecondaryView.newBoard
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
        if UserDefaults.standard.value(forKey: "currentUserEmail") is String {
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
                    if self.paperStorageViewController.viewControllers.first is PaperStorageViewController {
                        let writtenVC = WrittenPaperViewController()
                        self.paperStorageViewController.pushViewController(writtenVC, animated: true) {
                            LocalDatabaseFileManager.shared.fetchPaper(paperId: paperId)
                            FirestoreManager.shared.fetchPaper(paperId: paperId)
                        }
                    }
                }
            }
        } else {
            if let currentNavVC = viewControllers[1] as? UINavigationController {
                currentNavVC.popToRootViewController(true) {
                    self.setViewController(self.giftStorageViewController, for: .secondary)
                    if self.giftStorageViewController.viewControllers.first is GiftStorageViewController {
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
        guard let nextView = notification.userInfo?[NotificationViewKey.view] as? SecondaryView else { return }
        switch nextView {
        case .newBoard:
            setViewController(paperTemplateSelectViewController, for: .secondary)
            currentSecondaryView = .newBoard
        case .feed:
            if currentSecondaryView == .newBoard {
                self.paperTemplateSelectViewController.popToRootViewController(animated: false)
                self.paperStorageViewController.pushViewController(WrittenPaperViewController(), animated: false)
                setViewController(paperStorageViewController, for: .secondary)
            } else {
                self.paperStorageViewController.popToRootViewController(animated: false)
            }
            currentSecondaryView = .feed
        case .giftBox:
            setViewController(giftStorageViewController, for: .secondary)
            currentSecondaryView = .giftBox
        case .setting:
            setViewController(appSettingViewController, for: .secondary)
            currentSecondaryView = .setting
        case .profile:
            if UserDefaults.standard.value(forKey: "currentUserEmail") is String {
                self.appSettingViewController.popViewController(false) {
                    self.appSettingViewController.pushViewController(SettingScreenViewController(), animated: false)
                }
                
            } else {
                self.appSettingViewController.popViewController(false) {
                    self.appSettingViewController.pushViewController(SignInViewController(), animated: false)
                }
            }
            currentSecondaryView = .setting
        }
        self.currentSecondaryView = nextView
    }
    
    @objc private func changeSecondaryViewFromSidebar(notification: Notification) {
        guard let nextView = notification.userInfo?[NotificationViewKey.view] as? SecondaryView,
            !((nextView == currentSecondaryView) && (nextView != .profile)) else {
            return
        }
        
        switch nextView {
        case .newBoard:
            setViewController(paperTemplateSelectViewController, for: .secondary)
            currentSecondaryView = .newBoard
        case .feed:
            setViewController(paperStorageViewController, for: .secondary)
            currentSecondaryView = .feed
        case .giftBox:
            setViewController(giftStorageViewController, for: .secondary)
            currentSecondaryView = .giftBox
        case .setting:
            setViewController(appSettingViewController, for: .secondary)
            currentSecondaryView = .setting
        case .profile:
            if UserDefaults.standard.value(forKey: "currentUserEmail") is String {
                self.appSettingViewController.popToRootViewController(animated: false)
                self.appSettingViewController.pushViewController(SettingScreenViewController(), animated: false)
                if currentSecondaryView != .setting {
                    setViewController(appSettingViewController, for: .secondary)
                }
            } else {
                self.appSettingViewController.popToRootViewController(animated: false)
                self.appSettingViewController.pushViewController(SignInViewController(), animated: false)
                if currentSecondaryView != .setting {
                    setViewController(appSettingViewController, for: .secondary)
                }
            }
            currentSecondaryView = .setting
            self.currentSecondaryView = nextView
        }
    }
    
    @objc private func initializeNavigationStack(notification: Notification) {
        guard let object = notification.userInfo?[NotificationViewKey.view] as? String else { return }
        switch object {
        case "signOut":
            paperTemplateSelectViewController.popToRootViewController(animated: false)
            paperStorageViewController.popToRootViewController(animated: false)
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
