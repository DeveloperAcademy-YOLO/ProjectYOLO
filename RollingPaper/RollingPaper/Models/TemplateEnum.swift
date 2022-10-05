//
//  TemplateEnum.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation

enum TemplateEnum: String, CaseIterable {
    case halloween
    case school
    case grid
    case white
    case dark
    case sunrise
    
    var template: TemplateModel {
        switch self {
        case .halloween:
            return TemplateModel(templateString: "Halloween", colorHexes: [], stickerNames: [])
        case .school:
            return TemplateModel(templateString: "School", colorHexes: [], stickerNames: [])
        case .grid:
            return TemplateModel(templateString: "Grid", colorHexes: [], stickerNames: [])
        case .white:
            return TemplateModel(templateString: "White", colorHexes: [], stickerNames: [])
        case .dark:
            return TemplateModel(templateString: "Dark", colorHexes: [], stickerNames: [])
        case .sunrise:
            return TemplateModel(templateString: "Sunrise", colorHexes: [], stickerNames: [])
        }
    }
}
