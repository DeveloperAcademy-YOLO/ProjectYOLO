//
//  AppSettingCategoryModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/14.
//

import Foundation
import UIKit

struct AppSettingSectionModel: Hashable {
    
    init(title: String, subCells: [AppSettingSectionSubCellModel]? = nil) {
        self.title = title
        self.subCells = subCells
    }
    
    let title: String
    let subCells: [AppSettingSectionSubCellModel]?
}

struct AppSettingSectionSubCellModel: Hashable {
    let title: String
    let icon: UIImage?
}

enum ListItem: Hashable {
    case header(AppSettingSectionModel)
    case subCell(AppSettingSectionSubCellModel)
}
