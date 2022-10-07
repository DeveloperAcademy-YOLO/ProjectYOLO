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
            return TemplateModel(templateString: "halloween", colorHexes: [], stickerNames: [])
        case .school:
            return TemplateModel(templateString: "school", colorHexes: [], stickerNames: [])
        case .grid:
            return TemplateModel(templateString: "grid", colorHexes: [], stickerNames: [])
        case .white:
            return TemplateModel(templateString: "white", colorHexes: [], stickerNames: [])
        case .dark:
            return TemplateModel(templateString: "dark", colorHexes: [], stickerNames: [])
        case .sunrise:
            return TemplateModel(templateString: "sunrise", colorHexes: [], stickerNames: [])
        }
    }
}
