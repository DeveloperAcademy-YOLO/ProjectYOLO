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
    
    func setGradient(color1: UIColor, color2: UIColor, bounds: CGRect) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.frame = bounds
        layer.addSublayer(gradient)
    }
}
