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

        // dismiss scheduled notifications
        dismiss(Constants.Notification.ChatID, id: chat.id)

        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertTitle = "New Message"
        notification.alertBody = "\(message.nick) : \(message.body)"
        notification.alertAction = "open"
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.category = "lol_message"
        notification.userInfo = [
            Constants.Notification.ChatID: chat.id,
            Constants.Notification.Redirect: !UIApplication.isActive()]
        notification.applicationIconBadgeNumber = chat.unread

        return notification
    }

    class func create(title: String, body: String) -> UILocalNotification {
        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = body
        notification.alertAction = "open"
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.category = "lol_alert"
        notification.userInfo = ["uid" : "alert"]

        return notification
    }

    class func dismiss(key: String, id: String) {
        let application = UIApplication.sharedApplication()
        if let scheduledNotifications = application.scheduledLocalNotifications {
            scheduledNotifications.forEach {
                notification in
                if let uid = notification.userInfo?[key] as? String {
                    if uid == id {
                        application.cancelLocalNotification(notification)
                    }
                }
            }
        }
    }
}