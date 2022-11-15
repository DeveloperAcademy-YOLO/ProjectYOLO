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
    private var sidebarViewController: SidebarViewController!
    private var currentSecondaryView = "새 페이퍼"
    private var paperTemplateSelectViewController: UINavigationController!
    private var paperStorageViewController: UINavigationController!
    private var giftboxViewController: UINavigationController!
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
            selector: #selector(changeSecondaryView(noitificaiton:)),
            name: Notification.Name.viewChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSecondaryViewFromSidebar(noitificaiton:)),
            name: Notification.Name.viewChangeFromSidebar,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeFromDeeplink),
            name: .deeplink,
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
        sidebarViewController = SidebarViewController()
        paperTemplateSelectViewController = UINavigationController(rootViewController: PaperTemplateSelectViewController())
        paperStorageViewController = UINavigationController(rootViewController: PaperStorageViewController())
        // TODO: GiftboxViewController() 생성
        // settingScreenViewController = UINavigationController(rootViewController: )
        if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
            settingScreenViewController = UINavigationController(rootViewController: SettingScreenViewController())
        } else {
            settingScreenViewController = UINavigationController(rootViewController: SignInViewController())
        }
        let sidebar = UINavigationController(rootViewController: self.sidebarViewController)
        self.viewControllers = [sidebar, paperTemplateSelectViewController]
    }
    
    @objc func changeFromDeeplink(notification: Notification) {
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
            if let currentNavVC = viewControllers[1] as? UINavigationController {
                currentNavVC.popToRootViewController(true) {
                    self.setViewController(self.giftboxViewController, for: .secondary)
                    if let giftBoxVC = self.giftboxViewController.viewControllers.first as? GiftBoxViewController {
                        let giftVC = GiftPaperViewController()
                        self.giftboxViewController.pushViewController(giftVC, animated: true) {
                            LocalDatabaseFileManager.shared.fetchPaper(paperId: paperId)
                            FirestoreManager.shared.fetchPaper(paperId: paperId)
                        }
                    }
                }
            }
        }
    }
    
    @objc func changeSecondaryView(noitificaiton: Notification) {
        guard let object = noitificaiton.userInfo?[NotificationViewKey.view] as? String else { return }
        switch object {
        case "새 페이퍼":
            setViewController(paperTemplateSelectViewController, for: .secondary)
        case "보관함":
            if currentSecondaryView == "새 페이퍼" {
                self.paperTemplateSelectViewController.popToRootViewController(animated: false)
                self.paperStorageViewController.pushViewController(WrittenPaperViewController(), animated: false)
                setViewController(paperStorageViewController, for: .secondary)
            } else {
                self.paperStorageViewController.popToRootViewController(animated: false)
            }
        // TODO: GiftboxViewController() 생성
        case "선물 상자":
            setViewController(giftboxViewController, for: .secondary)
        case "설정":
            if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
                self.settingScreenViewController.setViewControllers([SettingScreenViewController()], animated: false)
            } else {
                self.settingScreenViewController.setViewControllers([SignInViewController()], animated: false)
            }
        default :
            break
        }
        self.currentSecondaryView = object
    }
    
    @objc func changeSecondaryViewFromSidebar(noitificaiton: Notification) {
        guard let object = noitificaiton.userInfo?[NotificationViewKey.view] as? String else { return }
        if self.currentSecondaryView == object {
            return
        }
        switch object {
        case "새 페이퍼":
            setViewController(paperTemplateSelectViewController, for: .secondary)
        case "보관함":
            setViewController(paperStorageViewController, for: .secondary)
        // TODO: GiftboxViewController() 생성
        case "선물 상자":
            setViewController(giftboxViewController, for: .secondary)
        case "설정":
            setViewController(settingScreenViewController, for: .secondary)
        default :
            break
        }
        self.currentSecondaryView = object
    }
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        if displayMode.rawValue == 1 {
            input.send(.viewIsClosed)
        } else {
            input.send(.viewIsOpened)
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return self.viewControllers.last
    }
}
