//
//  SecondaryViewEnum.swift
//  RollingPaper
//
//  Created by KellyChui on 2023/07/01.
//

import Foundation

enum SecondaryView: String {
    case newBoard = "새로운 보드"
    case feed = "담벼락"
    case giftBox = "선물 상자"
    case setting = "설정"
    case profile = "프로필"
    var category: CategoryModel {
        switch self {
        case .newBoard:
            return CategoryModel(name: self.rawValue, icon: "square.and.pencil")
        case .feed:
            return CategoryModel(name: self.rawValue, icon: "square.grid.2x2")
        case .giftBox:
            return CategoryModel(name: self.rawValue, icon: "giftcard")
        case .setting:
            return CategoryModel(name: self.rawValue, icon: "gearshape")
        default:
            return CategoryModel(name: self.rawValue, icon: "x.square")
        }
    }
}
