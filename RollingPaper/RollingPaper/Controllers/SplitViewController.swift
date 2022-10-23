//
//  ViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit
import Combine
import CombineCocoa

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate, SidebarViewControllerDelegate {
    
    private let splitViewManager = SplitViewManager.shared
    private let input: PassthroughSubject<SplitViewManager.Input, Never> = .init()
    private var sidebarViewController: SidebarViewController!
    // private var templateViewController: PaperTemplateSelectViewController!
    // private var storageViewController: PaperStorageViewController!
    // private var mainViewController: MainViewController!
    // private var settingViewController: SettingScreenViewController!
    private var current = "페이퍼 템플릿"
    private var paperTemplateSelectViewController: UINavigationController!
    private var paperStorageViewController: UINavigationController!
    private var settingScreenViewController: UINavigationController!
    
    var sideBarCategories: [CategoryModel] = [
        CategoryModel(name: "페이퍼 템플릿", icon: "doc.on.doc"),
        CategoryModel(name: "페이퍼 보관함", icon: "folder"),
        CategoryModel(name: "설정", icon: "gearshape")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(changeSecondaryView(noitificaiton:)), name: Notification.Name.viewChange, object: nil)
        self.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
        self.presentsWithGesture = true
        self.loadViewControllers()
        self.sidebarViewController.show(categories: self.sideBarCategories)
        self.preferredPrimaryColumnWidthFraction = 0.25
        delegate = self
        splitViewManager.transform(input: input.eraseToAnyPublisher())
    }
    
    private func loadViewControllers() {
        self.sidebarViewController.delegate = self
        self.sidebarViewController = SidebarViewController()
        self.paperTemplateSelectViewController = UINavigationController(rootViewController: PaperTemplateSelectViewController())
        self.paperStorageViewController = UINavigationController(rootViewController: PaperStorageViewController())
        self.settingScreenViewController = UINavigationController(rootViewController: SettingScreenViewController())
        let sidebar = UINavigationController(rootViewController: self.sidebarViewController)
        self.viewControllers = [sidebar, paperTemplateSelectViewController]
    }
    /*
    func didSelectCategory(_ category: CategoryModel) {
        let templateViewController = UINavigationController(rootViewController: self.templateViewController)
        let paperStorageViewController = UINavigationController(rootViewController: self.storageViewController)
        let settingScreenViewController = UINavigationController(rootViewController: self.settingViewController)
        
        switch category.name {
        case "페이퍼 템플릿":
            if !(self.viewControllers[1] is PaperTemplateSelectViewController) {
                self.viewControllers[1] = templateViewController
            }
        case "페이퍼 보관함":
            if !(self.viewControllers[1] is PaperStorageViewController) {
                self.viewControllers[1] = paperStorageViewController
            }
        case "설정":
            if !(self.viewControllers[1] is SettingScreenViewController) {
                if let currentUserEmail = UserDefaults.standard.value(forKey: "currentUserEmail") as? String {
                    print(currentUserEmail)
                    self.viewControllers[1] = settingScreenViewController
                } else {
                    self.viewControllers[1] = UINavigationController(rootViewController: SignInViewController())
                }
            }
        default:
            break
        }
    }
    */
    @objc func changeSecondaryView(noitificaiton: Notification) {
        guard let object = noitificaiton.userInfo?[NotificationViewKey.view] as? String else { return }
        if self.current == object {
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
        self.current = object
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
