//
//  ContentViewControllerPresentation.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/04.
//

import UIKit

enum ContentViewControllerPresentation {
    case embed(ContentViewController)
    case push(UIViewController)
    case modal(UIViewController)
}
