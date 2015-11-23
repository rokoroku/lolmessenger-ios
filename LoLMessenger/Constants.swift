//
// Created by 김영록 on 2015. 10. 1..
// Copyright (c) 2015 rokoroku. All rights reserved.
//

import UIKit
import Foundation

struct Constants {
    struct Notification {
        struct Category {
            static let Message = "message"
            static let Subscribtion = "subscribe"
            static let Connection = "connection"
            static let DebugConnection = "connection_debug"
        }
        struct UserInfo {
            static let Chat = "chat"
            static let Subscription = "subscribe"
            static let ChatID = "chatid"
            static let AppState = "appstate"
        }
    }

    struct Key {
        static let Username = "username"
        static let Password = "password"
        static let Region = "region"
        static func Presence(userid: String) -> String {
            return "presence_\(userid)"
        }
        static func Alarm(userid: String) -> String {
            return "alarm_\(userid)"
        }
        static func NotificationCategory(notification: UILocalNotification) -> String? {
            if let category = notification.category {
                return "noti_\(category)"
            }
            return nil
        }
    }

    struct XMPP {
        struct Domain {
            static let User = "pvp.net"
            static let Room = "lvl.pvp.net"
        }
        struct Resource {
            static let PC = "xiff"
            static let Mobile = "iOS"
        }
        static let DefaultGroup = "**Default"
        static var DefaultStatus:String { return Localized("Using iOS Client") }
        static var GeneralGroup:String { return Localized("General") }
        static var OfflineGroup:String { return Localized("Offline") }
        static var Unknown:String { return Localized("Unknown") }
    }

    struct Segue {
        static let EnterChat = "EnterChat"
        static let SummonerModal = "SummonerModal"
    }
}
