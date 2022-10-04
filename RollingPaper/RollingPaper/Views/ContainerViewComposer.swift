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
       // let myAccountViewController = MyAccountViewController()
        let sideMenuItems = [
            SideMenuItem(icon: UIImage(systemName: "doc.on.doc"),
                         name: "페이퍼 템플릿",
                         viewController: .embed(paperTemplateViewController)),
            SideMenuItem(icon: UIImage(systemName: "folder"),
                         name: "페이퍼 보관함",
                         viewController: .embed(paperStorageViewController)),
            SideMenuItem(icon: UIImage(systemName: "gearshape"),
                         name: "설정",
                         viewController: .push(settingsViewController)),
//            SideMenuItem(icon: UIImage(systemName: "person"),
//                         name: "회원가입",
//                         viewController: .modal(myAccountViewController))
        ]
        let sideMenuViewController = SideMenuViewController(sideMenuItems: sideMenuItems)
        let container = ContainerViewController(sideMenuViewController: sideMenuViewController,
                                                rootViewController: paperTemplateViewController)

        return container
    }
}
