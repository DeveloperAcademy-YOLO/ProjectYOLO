//
//  UIView+Extensions.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/06.
//

import Foundation
import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        for view in views {
            addSubview(view)
        }
    }
}
