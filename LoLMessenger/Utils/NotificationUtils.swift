//
//  NotificationUtils.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 21..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import AVFoundation

class NotificationUtils {

    static func schedule(notification: UILocalNotification) {
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        if let key = Constants.Key.NotificationCategory(notification) {
            let notificationData = NSKeyedArchiver.archivedDataWithRootObject(notification)
            NSUserDefaults.standardUserDefaults().setObject(notificationData, forKey: key)
        }
    }

    static func dismiss(category: String) {
        let key = "noti_\(category)"
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let application = UIApplication.sharedApplication()
        if let existingNotificationData = userDefaults.objectForKey(key) as? NSData,
            existingNotification = NSKeyedUnarchiver.unarchiveObjectWithData(existingNotificationData) as? UILocalNotification {

            // Cancel notification if scheduled, delete it from notification center if already delivered
            application.cancelLocalNotification(existingNotification)

            // Clean up
            userDefaults.removeObjectForKey(key)
        }

        if let scheduledNotifications = application.scheduledLocalNotifications {
            scheduledNotifications.forEach { notification in
                if notification.category == category {
                    application.cancelLocalNotification(notification)
                }
            }
        }
    }

    static func create(chat: LeagueChat, message: LeagueMessage) -> UILocalNotification {

        // create a corresponding local notification
        let notification = UILocalNotification()
        if #available(iOS 8.2, *) {
            notification.alertTitle = Localized("New message arrived")
        } else {
            // Fallback on earlier versions
        }
        notification.alertBody = "\(message.nick) : \(message.body)"
        notification.alertAction = Localized("Open")
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

    static func create(title title: String, body: String, action: String = Localized("Open"), category: String, userinfo: [String: AnyObject]? = nil) -> UILocalNotification {
        // create a corresponding local notification
        let notification = UILocalNotification()

        if #available(iOS 8.2, *) {
            notification.alertTitle = title
        }
        notification.alertBody = body
        notification.alertAction = action

        if StoredProperties.Settings.notifyWithSound.value {
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        }

        notification.category = category
        notification.userInfo = userinfo

        return notification
    }

    static func alert(vibrate: Bool = StoredProperties.Settings.notifyWithVibrate.value, sound: Bool = StoredProperties.Settings.notifyWithSound.value) {
            if vibrate {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            if sound {
                AudioServicesPlaySystemSound(1002)
            }
    }

}