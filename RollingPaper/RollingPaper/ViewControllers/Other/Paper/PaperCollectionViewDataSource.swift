//
//  PaperCollectionViewDataSource.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/12/02.
//

import UIKit

enum Section: Int, CaseIterable {
    case first
}

class PaperCollectionViewDataSource: UICollectionViewDiffableDataSource<Section, CardModel> {
}
