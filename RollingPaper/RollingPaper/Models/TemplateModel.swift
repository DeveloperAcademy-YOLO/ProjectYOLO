//
//  TemplateModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import UIKit

struct TemplateModel: Codable {
    let templateString: String
    let colorHexes: [Int]
    let stickerNames: [String]
    var colors: [UIColor] {
        return colorHexes.map({ UIColor(rgb: $0) })
    }
    var thumbnailString: String {
        return "thumbnail_\(templateString).jpg"
    }
    var thumbnail: UIImage? {
        return UIImage(named: thumbnailString)
    }
    var template: UIImage? {
        return UIImage(named: templateString)
    }
}
//TODO: Color -> Codable에 맞춰서 넣기
