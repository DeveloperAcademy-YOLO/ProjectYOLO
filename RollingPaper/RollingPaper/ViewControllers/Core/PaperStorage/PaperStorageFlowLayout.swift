//
//  PaperStorageFlowLayout.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/09.
//

import UIKit

class PaperStorageFlowLayout: UICollectionViewFlowLayout {
    let cellHorizontalSpacing: CGFloat
    let inset: UIEdgeInsets

    init(cellSpacing: CGFloat, inset: UIEdgeInsets) {
        self.cellHorizontalSpacing = cellSpacing
        self.inset = inset
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        sectionInset = inset
        
        let attributes = super.layoutAttributesForElements(in: rect)
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach({ layoutAttribute in
            if layoutAttribute.representedElementKind == UICollectionView.elementKindSectionHeader {
                return
            }
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            layoutAttribute.frame.origin.x = leftMargin
            leftMargin += layoutAttribute.frame.width + cellHorizontalSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        })
        return attributes
    }
}
