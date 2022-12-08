//
//  UNUserNotificationCenter+Extensions.swift
//  RollingPaper
//
//  Created by Junyeong Park on 2022/10/17.
//

import Foundation
import UserNotifications
import UIKit

extension UNUserNotificationCenter {
    func addPaperRequest(paper: PaperModel) {
        let currentBadgeCount = UserDefaults.standard.value(forKey: "currentBadgeCount") as? Int ?? 0
        let date = paper.endTime
        let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: date)
        let content = UNMutableNotificationContent()
        content.title = "\(paper.title) 보드 완성!"
        content.body = "작성이 끝난 보드를 열어보세요!"
        content.sound = .default
        content.badge = (currentBadgeCount + 1) as NSNumber
        content.userInfo = ["paperId": paper.paperId, "type": "made"]
        UserDefaults.standard.set(currentBadgeCount + 1, forKey: "currentBadgeCount")
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
        let request = UNNotificationRequest(identifier: paper.paperId, content: content, trigger: trigger)
        add(request, withCompletionHandler: nil)
    }
}
