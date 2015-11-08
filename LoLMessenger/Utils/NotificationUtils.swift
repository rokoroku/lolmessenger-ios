//
//  NotificationUtils.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 21..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class NotificationUtils {
    class func create(chat: LeagueChat, message: LeagueMessage) -> UILocalNotification {

        // create a corresponding local notification
        let notification = UILocalNotification()
        if #available(iOS 8.2, *) {
            notification.alertTitle = NSLocalizedString("New Message", comment: "New Message Alert Title")
        } else {
            // Fallback on earlier versions
        }
        notification.alertBody = "\(message.nick) : \(message.body)"
        notification.alertAction = NSLocalizedString("Open", comment: "New Message Alert Action")
        if StoredProperties.Settings.notifyWithSound.value {
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        }
        notification.category = "message"
        notification.userInfo = [
            Constants.Notification.UserInfo.ChatID: chat.id,
            Constants.Notification.UserInfo.AppState: UIApplication.isActive()]
        notification.applicationIconBadgeNumber = chat.unread

        return notification
    }

    class func create(title: String, body: String, category: String, userinfo: [String: AnyObject]? = nil) -> UILocalNotification {
        // create a corresponding local notification
        let notification = UILocalNotification()

        if #available(iOS 8.2, *) {
            notification.alertTitle = title
        }
        notification.alertBody = body
        notification.alertAction = "Open"

        if StoredProperties.Settings.notifyWithSound.value {
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        }

        notification.category = category
        notification.userInfo = userinfo

        return notification
    }

    class func dismissCategory(category: String) {
        let application = UIApplication.sharedApplication()
        if let scheduledNotifications = application.scheduledLocalNotifications {
            scheduledNotifications.forEach { notification in
                if notification.category == category {
                    application.cancelLocalNotification(notification)
                }
            }
        }
    }

    class func dismiss(key: String, id: String) {
        let application = UIApplication.sharedApplication()
        if let scheduledNotifications = application.scheduledLocalNotifications {
            scheduledNotifications.forEach { notification in
                if let uid = notification.userInfo?[key] as? String {
                    if uid == id {
                        application.cancelLocalNotification(notification)
                    }
                }
            }
        }
    }
}