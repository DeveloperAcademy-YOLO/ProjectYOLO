//
//  UserModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation

struct UserModel: Codable {
    let email: String
    var profileUrl: String?
    var name: String
}
