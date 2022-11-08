//
//  UIButton+Extensions.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/18.
//

import Foundation
import UIKit

extension UIButton {
    func addLeftPadding(_ padding: CGFloat) {
        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: padding, bottom: 0.0, right: -padding)
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: padding)
    }
}

