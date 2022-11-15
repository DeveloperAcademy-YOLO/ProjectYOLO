//
//  String+Extensions.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/11.
//

import Foundation

extension String {
    func substring(start: Int, end: Int) -> String {
        guard start < count, end >= 0, end - start >= 0 else {
            return ""
        }
        let startIndex = index(self.startIndex, offsetBy: start)
        let endIndex = index(self.startIndex, offsetBy: end)
        return String(self[startIndex ..< endIndex])
    }
}
