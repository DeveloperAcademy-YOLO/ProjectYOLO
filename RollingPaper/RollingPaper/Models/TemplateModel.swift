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
    let colorNames: [String]
    let stickerNames: [String]
//    var colors: [UIColor] {
//        return ~
//    }
//    var thumbnail: UIImage {
//        return ~
//    }
    var thumbnailString: String {
        return "thumnail_\(templateString).jpg"
    }
    var thumbnail: UIImage? {
        return UIImage(named: thumbnailString)
    }
    
    var template: UIImage? {
        return UIImage(named: templateString)
    }
}
//TODO: Color -> Codable에 맞춰서 넣기
