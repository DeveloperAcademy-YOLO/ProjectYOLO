//
//  SideMenuDelegate.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/04.
//

import Foundation

protocol SideMenuDelegate: AnyObject {
    func menuButtonTapped()
    func itemSelected(item: ContentViewControllerPresentation)
}
