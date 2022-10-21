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
            return TemplateModel(templateString: "halloween", templateTitle: "할로윈", templateDescription: "달콤하고도 으스스한 스티커와 카드로 이뤄진 테마", colorHexes: [], stickerNames: [])
        case .school:
            return TemplateModel(templateString: "school", templateTitle: "학교", templateDescription: "학교학교", colorHexes: [], stickerNames: [])
        case .grid:
            return TemplateModel(templateString: "grid", templateTitle: "모눈종이", templateDescription: "모눈모눈", colorHexes: [], stickerNames: [])
        case .white:
            return TemplateModel(templateString: "white", templateTitle: "기본", templateDescription: "기본기본", colorHexes: [], stickerNames: [])
        case .dark:
            return TemplateModel(templateString: "dark", templateTitle: "다크", templateDescription: "다크다크", colorHexes: [], stickerNames: [])
        case .sunrise:
            return TemplateModel(templateString: "sunrise", templateTitle: "일출", templateDescription: "일출일출", colorHexes: [], stickerNames: [])
        }
    }
}
