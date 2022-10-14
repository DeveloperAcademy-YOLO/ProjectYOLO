//
//  ViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate, SidebarViewControllerDelegate {
    
    func didSelectCategory(_ category: CategoryModel) {
        var secondaryVC = UIViewController()
        switch category.name {
        case "페이퍼 템플릿":
            secondaryVC = TemplateSelectViewController()
        case "페이퍼 보관함":
            secondaryVC = MainViewController()
        case "설정":
            secondaryVC = SettingScreenViewController()
        default:
            secondaryVC = MainViewController()
        }
        self.showDetailViewController(secondaryVC, sender: nil)
    }
    
    
    var sideBarCategories: [CategoryModel] = [
        CategoryModel(name: "페이퍼 템플릿", icon: "doc.on.doc"),
        CategoryModel(name: "페이퍼 보관함", icon: "folder"),
        CategoryModel(name: "설정", icon: "gearshape")
    ]
    private var sidebarViewController: SidebarViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
        self.presentsWithGesture = true
        self.preferredPrimaryColumnWidth = 320
        self.loadViewControllers()
        self.sidebarViewController.show(categories: self.sideBarCategories)
        self.preferredPrimaryColumnWidthFraction = 0.3
        self.minimumPrimaryColumnWidth = 320
        self.maximumPrimaryColumnWidth = 640
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
         return true
     }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return self.viewControllers.last
    }
    
    private func loadViewControllers() {
        self.sidebarViewController = SidebarViewController()
        self.sidebarViewController.delegate = self
        let navController = UINavigationController(rootViewController: self.sidebarViewController)
        let detail = TemplateSelectViewController()
        self.viewControllers = [navController, detail]
    }
}
