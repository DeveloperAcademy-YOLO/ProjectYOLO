//
//  TemplateEnum.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation

enum TemplateEnum: String, CaseIterable {
    case beige
    case halloween
  //  case school
  //  case grid
  //  case dark
  //  case sunrise
    
    var template: TemplateModel {
        switch self {
        case .beige:
            return TemplateModel(templateString: "beige", templateTitle: "베이지", templateDescription: "베이지색으로 구성된 템플릿", colorHexes: [], stickerNames: ["Beige_maple", "Beige_cat", "Beige_dog2", "Beige_dog", "Beige_basket", "Beige_duck", "Beige_gingerbread", "Beige_old_paper", "Beige_ball"], backgroundImageNames: ["Rectangle_beige1", "Rectangle_beige2", "Rectangle_beige3", "Rectangle_beige4"])
        case .halloween:
            return TemplateModel(templateString: "halloween", templateTitle: "할로윈", templateDescription: "달콤하고도 으스스한 스티커와 카드로 이뤄진 테마", colorHexes: [], stickerNames: ["Halloween_Pumpkin", "Halloween_Candy", "Halloween_Bat", "Halloween_Ghost", "Halloween_StickCandy", "Halloween_Pumpkin2", "Halloween_Pot_Green", "Halloween_Pot_Purple", "Halloween_Pot_Red", "Halloween_Hat", "Halloween_Pumpkin_Green", "Halloween_Pumpkin_Orange", "Halloween_Pumpkin_Pale", "Halloween_Ghost2", "Halloween_Ghost_with_legs", "Halloween_Bone", "Halloween_Blood"], backgroundImageNames: ["Rectangle_white", "Pattern_Bone", "Pattern_Pumpkin", "Pattern_Skull"])
//        case .school:
//            return TemplateModel(templateString: "school", templateTitle: "학교", templateDescription: "학교학교", colorHexes: [], stickerNames: [], backgroundImageNames: [])
//        case .grid:
//            return TemplateModel(templateString: "grid", templateTitle: "모눈종이", templateDescription: "모눈모눈", colorHexes: [], stickerNames: [], backgroundImageNames: [])
//        case .dark:
//            return TemplateModel(templateString: "dark", templateTitle: "다크", templateDescription: "다크다크", colorHexes: [], stickerNames: [], backgroundImageNames: [])
//        case .sunrise:
//            return TemplateModel(templateString: "sunrise", templateTitle: "일출", templateDescription: "일출일출", colorHexes: [], stickerNames: [], backgroundImageNames: [])
        }
    }
}
