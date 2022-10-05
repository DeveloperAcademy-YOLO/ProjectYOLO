//
//  PaperModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation

struct PaperModel: Codable {
    var creator: UserModel?
    var cards: [CardModel]
    let date: Date
    let title: String
    var paperId = UUID().uuidString
    var linkUrl: String?
    let templateString: String
    let validTime: Date
    // isClosed -> Computed
//    var template: TemplateModel {
//        return TemplateEnum(rawValue: templateString).template
//    }
}
