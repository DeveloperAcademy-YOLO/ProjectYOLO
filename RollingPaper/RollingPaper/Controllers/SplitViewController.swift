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
    private var currentSecondaryView = "페이퍼 템플릿"
    private var paperTemplateSelectViewController: UINavigationController!
    private var paperStorageViewController: UINavigationController!
    private var settingScreenViewController: UINavigationController!
    private var signInViewController: UINavigationController!
    
    var sideBarCategories: [CategoryModel] = [
        CategoryModel(name: "페이퍼 템플릿", icon: "doc.on.doc"),
        CategoryModel(name: "페이퍼 보관함", icon: "folder"),
        CategoryModel(name: "설정", icon: "gearshape")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
        self.presentsWithGesture = true
        self.loadViewControllers()
        self.sidebarViewController.show(categories: self.sideBarCategories)
        self.preferredPrimaryColumnWidthFraction = 0.25
        delegate = self
        splitViewManager.transform(input: input.eraseToAnyPublisher())
    }
    
    private func loadViewControllers() {
        self.sidebarViewController = SidebarViewController()
        self.paperTemplateSelectViewController = UINavigationController(rootViewController: PaperTemplateSelectViewController())
        self.paperStorageViewController = UINavigationController(rootViewController: PaperStorageViewController())
        self.settingScreenViewController = UINavigationController(rootViewController: SettingScreenViewController())
        
        if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
            settingScreenViewController.pushViewController(SignInViewController(), animated: false)
        }
        let sidebar = UINavigationController(rootViewController: self.sidebarViewController)
        self.viewControllers = [sidebar, paperTemplateSelectViewController]
    }
    
    @objc func changeSecondaryView(noitificaiton: Notification) {
        guard let object = noitificaiton.userInfo?[NotificationViewKey.view] as? String else { return }
        switch object {
        case "페이퍼 템플릿":
            self.viewControllers[1] = paperTemplateSelectViewController
        case "페이퍼 보관함":
            if currentSecondaryView == "페이퍼 보관함" {
//                self.paperStorageViewController = UINavigationController(rootViewController: PaperStorageViewController())
                self.viewControllers[1] = paperStorageViewController
            } else {
                if let currentNav = self.viewControllers[1] as? UINavigationController {
                    currentNav.popToRootViewController(true) {
                        self.viewControllers[1] = self.paperStorageViewController
                    }
                }
            }
        case "보관함 이동 후 카드 뷰":
            self.paperStorageViewController.pushViewController(WrittenPaperViewController(), animated: true)
            self.viewControllers[1] = paperStorageViewController
        case "설정":
            print("설정 변경 called")
            if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
//                print("현재 로그인 상태")
//                DispatchQueue.main.async {
//                    self.viewControllers[1] = self.settingScreenViewController
//                }
                if let vc = self.viewControllers[1] as? UINavigationController {
                    vc.popViewController(animated: false)
                }
            } else {
                print("현재 로그아웃 상태")
//                DispatchQueue.main.async {
//                    self.viewControllers[1] =  self.signInViewController
//                }
                if let vc = self.viewControllers[1] as? UINavigationController {
                    vc.pushViewController(SignInViewController(), animated: false)
                }
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
        case "페이퍼 템플릿":
            self.viewControllers[1] = paperTemplateSelectViewController
        case "페이퍼 보관함":
            self.viewControllers[1] = paperStorageViewController
        case "설정":
            self.viewControllers[1] = settingScreenViewController
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
