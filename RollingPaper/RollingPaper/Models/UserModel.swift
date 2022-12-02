//
//  UserModel.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/05.
//

import Foundation

struct UserModel: Codable, Hashable {
    let email: String
    var profileUrl: String?
    var name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
}
