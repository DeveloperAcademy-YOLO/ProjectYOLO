//
//  ContainerViewComposer.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/04.
//

import UIKit

final class ContainerViewComposer {
    static func makeContainer() -> ContainerViewController {
        let paperTemplateViewController = PaperTemplateViewController()
        let paperStorageViewController = PaperStorageViewController()
        let settingsViewController = SettingViewController()
        let accountLoginViewController = AccountLoginViewController()
        let sideMenuItems = [
            SideBarItem(icon: UIImage(systemName: "doc.on.doc"),
                         name: "페이퍼 템플릿",
                         viewController: .embed(paperTemplateViewController)),
            SideBarItem(icon: UIImage(systemName: "folder"),
                         name: "페이퍼 보관함",
                         viewController: .embed(paperStorageViewController)),
            SideBarItem(icon: UIImage(systemName: "gearshape"),
                         name: "설정",
                         viewController: .push(settingsViewController)),
            SideBarItem(icon: UIImage(systemName: "person"),
                         name: "회원가입",
                         viewController: .modal(accountLoginViewController))
        ]
        let sideMenuViewController = SideBarViewController(sideMenuItems: sideMenuItems)
        let container = ContainerViewController(sideMenuViewController: sideMenuViewController,
                                                rootViewController: paperTemplateViewController)

        return container
    }
}
