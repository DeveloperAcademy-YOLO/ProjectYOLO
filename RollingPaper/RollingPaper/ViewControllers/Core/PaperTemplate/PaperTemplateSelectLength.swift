//
//  PaperTemplateSelectLength.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/14.
//

import UIKit

final class PaperTemplateSelectLength {
    static let templateThumbnailWidth: CGFloat = (UIScreen.main.bounds.width*0.75-(24*5))/4
    static let templateThumbnailHeight: CGFloat = templateThumbnailWidth*0.75
    static let templateThumbnailCornerRadius: CGFloat = 12
    static let templateTitleHeight: CGFloat = 19
    static let templateTitleTopMargin: CGFloat = 16
    static let cellWidth: CGFloat = templateThumbnailWidth
    static let cellHeight: CGFloat = templateThumbnailHeight + templateTitleTopMargin + templateTitleHeight
    static let cellHorizontalSpace: CGFloat = 20
    static let cellVerticalSpace: CGFloat = 28
    static let sectionTopMargin: CGFloat = 28
    static let sectionBottomMargin: CGFloat = 48
    static let sectionRightMargin: CGFloat = 28
    static let sectionLeftMargin: CGFloat = 28
    static let headerWidth: CGFloat = 116
    static let headerHeight: CGFloat = 29
    static let headerLeftMargin: CGFloat = 34
}
