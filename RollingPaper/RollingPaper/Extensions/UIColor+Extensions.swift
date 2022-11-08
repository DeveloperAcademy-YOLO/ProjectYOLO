//
//  UIColor+Extensions.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    /*
     사용 방법
     let color = UIColor(red: 0xFF, green: 0xFF, blue: 0xFF)
     let color2 = UIColor(rgb: 0xFFFFFF)
     */
    
}

// MARK: TEEMO -> 수정 필요!
extension UIColor {
    
    static let toolColors = [UIColor.customLightGray, UIColor.customBlue, UIColor.customYellow, UIColor.customBlack, UIColor.customPurple]
    
    /// 다홍색
    static var customRed: UIColor {
        return UIColor(rgb: 0xE86334)
    }
    
    /// 보라색
    static var customPurple: UIColor {
        return UIColor(rgb: 0x7B65FF)
    }
    
    /// 파란색
    static var customBlue: UIColor {
        return UIColor(rgb: 0x6A94D1)
    }

    /// 노란색
    static var customYellow: UIColor {
        return UIColor(rgb: 0xFFCC1E)
    }
    
    /// 초록색
    static var customGreen: UIColor {
        return UIColor(rgb: 0x479783)
    }
    
    /// 검은색
    static var customBlack: UIColor {
        return UIColor(rgb: 0x2C213A)
    }

    /// 옅은 회색
    static var customLightGray: UIColor {
        return UIColor(rgb: 0xEFEFEF)
    }
    
    /// 모아보기 label 색
    static var customTitleBlack: UIColor {
        return UIColor(rgb: 0x101010)
    }
    
    /// 모아보기 Date 색
    static var customDateLabelBlack: UIColor {
        return UIColor(rgb: 0x393939)
    }
    
    /// 모아보기 업로드 시간  label 색
    static var customUploadTimeBlack: UIColor {
        return UIColor(rgb: 0x676767)
    }
    /// 리엑션 선택 뷰 label 색
    static var customLabelColor: UIColor {
        return UIColor(rgb: 0x858589)
    }
    
    /// 리엑션 선택 뷰 배경 색
    static var customReactionSelectBackgroundColor: UIColor {
        return UIColor(rgb: 0xF3F3F3)
    }
    
    /// CreateFamilyViewController label color
    static var customCreateFamilyButtonTitleColor: UIColor {
        return UIColor(rgb: 0x333333)
    }
    
    /// SidebarView BackgroundGray
    static var customSidebarBackgroundColor: UIColor {
        return UIColor(rgb: 0xF6F6F6)
    }
}
