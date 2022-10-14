//
//  UIStackView+Extensions.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/15.
//

import Foundation
import UIKit

extension UIStackView {
    func addStackViewBackground(Color: UIColor, radiusSize: CGFloat = 0.0) {
        let subView = UIView(frame: bounds)
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
        
        subView.layer.cornerRadius = radiusSize
        subView.layer.masksToBounds = true
        subView.clipsToBounds = true
    }
}
