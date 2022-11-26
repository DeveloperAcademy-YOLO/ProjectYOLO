//
//  Length.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import UIKit

final class PaperStorageLength {
    static let paperThumbnailCornerRadius: CGFloat = 12
    static let headerWidth: CGFloat = 200 // 임시
    static let headerHeight: CGFloat = 29
    static let headerLeftMargin: CGFloat = 37
    static let sectionTopMargin: CGFloat = 16
    static let sectionBottomMargin: CGFloat = 48
    static let sectionRightMargin: CGFloat = 36
    static let sectionLeftMargin: CGFloat = 36
    
    static let openedPaperThumbnailWidth1: CGFloat = (UIScreen.main.bounds.width*0.75-(sectionLeftMargin+sectionRightMargin+openedCellHorizontalSpace+2))/2
    static let openedPaperThumbnailWidth2: CGFloat = (UIScreen.main.bounds.width*1.0-(sectionLeftMargin+sectionRightMargin+openedCellHorizontalSpace+2))/2 
    static let openedPaperThumbnailHeight: CGFloat = openedPaperThumbnailWidth1*0.33
    static let openedPaperTitleBottomMargin: CGFloat = 16
    static let openedPaperTitleRightMargin: CGFloat = 16
    static let openedPaperTitleLeftMargin: CGFloat = 16
    static let openedCellHorizontalSpace: CGFloat = 18
    static let openedCellVerticalSpace: CGFloat = 18
    static let timerTopMargin: CGFloat = 8
    static let timerLeftMargin: CGFloat = 8
    static let timerTopPadding: CGFloat = 5
    static let timerBottomPadding: CGFloat = 5
    static let timerRightPadding: CGFloat = 7
    static let timerLeftPadding: CGFloat = 7
    static let timerSpace: CGFloat = 5
    static let timerCornerRadius: CGFloat = 8
    static let clockImageWidth: CGFloat = 14
    static let clockImageHeight: CGFloat = 14
    
    static let closedPaperThumbnailWidth1: CGFloat = (UIScreen.main.bounds.width*0.75-(sectionLeftMargin+sectionRightMargin+2))
    static let closedPaperThumbnailWidth2: CGFloat = (UIScreen.main.bounds.width*1.0-(sectionLeftMargin+sectionRightMargin+2))
    static let closedPaperThumbnailHeight: CGFloat = closedPaperThumbnailWidth1*0.16
    static let closedCellHorizontalSpace: CGFloat = 0
    static let closedCellVerticalSpace: CGFloat = 10
    static let labelSpacing: CGFloat = 10
}
