//
//  CardModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import UIKit

struct CardModel: Codable {
    var creator: UserModel?
    let date: Date
    var cardId = UUID().uuidString
    var contentURLString: String
}
