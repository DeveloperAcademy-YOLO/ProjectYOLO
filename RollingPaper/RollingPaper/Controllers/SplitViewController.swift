//
//  ViewController.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/05.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate, SidebarViewControllerDelegate {
    
    func didSelectCategory(_ category: CategoryModel) {
        switch category.name {
        case "페이퍼 템플릿":
            secondaryViewController?.navigationController?.popToRootViewController(false, completion: {self.secondaryViewController.navigationController?.pushViewController(TemplateSelectViewController(), animated: false)})
        case "페이퍼 보관함":
            secondaryViewController?.navigationController?.popToRootViewController(false, completion: {self.secondaryViewController.navigationController?.pushViewController(TemplateSelectViewController(), animated: false)})
        case "설정":
            secondaryViewController?.navigationController?.popToRootViewController(false, completion: {self.secondaryViewController.navigationController?.pushViewController(TemplateSelectViewController(), animated: false)})
        default:
            break
        }
    }
    
    
    var sideBarCategories: [CategoryModel] = [
        CategoryModel(name: "페이퍼 템플릿", icon: "doc.on.doc"),
        CategoryModel(name: "페이퍼 보관함", icon: "folder"),
        CategoryModel(name: "설정", icon: "gearshape")
    ]
    
    private var sidebarViewController: SidebarViewController!
    private var secondaryViewController: UIViewController!
    
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
        self.secondaryViewController = TemplateSelectViewController()
        self.viewControllers = [sidebarViewController, secondaryViewController]
    }
}
