//
//  PaperPreviewModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/12.
//

import Foundation

struct PaperPreviewModel: Codable {
    let paperId: String
    var creator: UserModel?
    let date: Date
    let endTime: Date
    var title: String
    let templateString: String
    var template: TemplateModel {
        return TemplateEnum(rawValue: templateString)?.template ?? TemplateEnum.beige.template
    }
    var thumbnailURLString: String?
}
