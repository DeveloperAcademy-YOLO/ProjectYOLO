//
//  AppSettingCategoryModel.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/11/14.
//

import Foundation

struct AppSettingUserProfileModel: Hashable {
    var name: String
    var photo: String
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

struct AppSettingCollectionCellModel: Hashable {
    let title: String
    let expand_view: UIView?
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
