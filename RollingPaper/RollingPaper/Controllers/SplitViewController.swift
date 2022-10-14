//
//  ViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate, SidebarViewControllerDelegate {
    
    func didSelectCategory(_ category: CategoryModel) {
        let sidebar = UINavigationController(rootViewController: self.sidebarViewController)
        let templateViewController = UINavigationController(rootViewController: self.templateViewController)
        let paperStorageViewController = UINavigationController(rootViewController: PaperStorageViewController())
        let mainViewController = UINavigationController(rootViewController: self.mainViewController)
        
        switch category.name {
        case "페이퍼 템플릿":
            if !(self.viewControllers[1] is TemplateSelectViewController) {
                self.viewControllers[1] = templateViewController
            }
        case "페이퍼 보관함":
            if !(self.viewControllers[1] is PaperStorageViewController) {
                self.viewControllers[1] = paperStorageViewController
            }
        case "설정":
            if !(self.viewControllers[1] is MainViewController) {
                self.viewControllers[1] = mainViewController
            }
        default:
            self.viewControllers[1] = mainViewController
        }
    }
    
    var sideBarCategories: [CategoryModel] = [
        CategoryModel(name: "페이퍼 템플릿", icon: "doc.on.doc"),
        CategoryModel(name: "페이퍼 보관함", icon: "folder"),
        CategoryModel(name: "설정", icon: "gearshape")
    ]
    private var sidebarViewController: SidebarViewController!
    private var templateViewController: TemplateSelectViewController!
    private var mainViewController: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
        self.presentsWithGesture = true
        self.loadViewControllers()
        self.sidebarViewController.show(categories: self.sideBarCategories)
        self.preferredPrimaryColumnWidthFraction = 0.25
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
         return true
     }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return self.viewControllers.last
    }
    
    private func loadViewControllers() {
        self.sidebarViewController = SidebarViewController()
        self.templateViewController = TemplateSelectViewController()
        self.mainViewController = MainViewController()
        self.sidebarViewController.delegate = self
        let sidebar = UINavigationController(rootViewController: self.sidebarViewController)
        let templateViewController = UINavigationController(rootViewController: self.templateViewController)
        self.viewControllers = [sidebar, templateViewController]
    }
}
