//
//  CardModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation
import UIKit

struct CardModel: Codable, Hashable {
    var creator: UserModel?
    let date: Date
    var cardId = UUID().uuidString
    var contentURLString: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(cardId)
    }
}
