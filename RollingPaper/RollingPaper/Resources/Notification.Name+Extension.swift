//
//  Notification.Name+Extension.swift
//  RollingPaper
//
//  Created by Kelly Chui on 2022/10/23.
//

import Foundation

extension Notification.Name {
    static let viewChange = Notification.Name("viewChange")
    static let viewChangeFromSidebar = Notification.Name("ViewChangeFromSidebar")
}

enum NotificationViewKey {
    case view
}
