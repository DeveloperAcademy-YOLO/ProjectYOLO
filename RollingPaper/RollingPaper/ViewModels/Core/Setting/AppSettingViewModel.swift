//
//  AppSettingViewModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/12.
//

import Foundation
import FirebaseAuth
import Combine

class AppSettingViewModel {
    
}

enum Section {
    case main
}

enum ListItem: Hashable {
    case header(AppSettingCollectionCellModel)
}

struct AppSettingCollectionCellModel: Hashable {
    let title: String
    let symbols: UIView
}

struct SFSymbolItem: Hashable {
    let name: String
    let image: UIImage
    
    init(name: String) {
        self.name = name
        self.image = UIImage(systemName: name)!
    }
}
