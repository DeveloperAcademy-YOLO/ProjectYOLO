//
//  UIImage+Extension.swift
//  RollingPaper
//
//  Created by SeungHwanKim on 2022/10/19.
//

import Foundation
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image{ _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
