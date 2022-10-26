//
//  PaperModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import UIKit

struct PaperModel: Codable {
    var paperId = UUID().uuidString
    var creator: UserModel?
    var cards: [CardModel]
    let date: Date
    let endTime: Date
    var title: String
    var linkUrl: String?
    var templateString: String
    var template: TemplateModel {
        return TemplateEnum(rawValue: templateString)?.template ?? TemplateEnum.beige.template
    }
    var thumbnailURLString: String?
    // TODO: 시간 계산, 남은 시간 compuited property로 추가
}
