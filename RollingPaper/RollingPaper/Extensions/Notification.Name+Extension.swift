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
    static let deeplink = Notification.Name("deeplink")
    static let viewInit = Notification.Name("viewInit")
    static let signUpDidSucceed = Notification.Name("signUpDidSucceed")
}

enum NotificationViewKey {
    case view
}
