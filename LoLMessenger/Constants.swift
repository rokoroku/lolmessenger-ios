//
// Created by 김영록 on 2015. 10. 1..
// Copyright (c) 2015 rokoroku. All rights reserved.
//

import Foundation

struct Constants {
    struct Notification {
        static let Chat = "chat"
        static let Subscription = "subscribe"
        static let ChatID = "chatid"
        static let AppState = "appstate"
    }

    struct Key {
        static let Username = "username"
        static let Password = "password"
        static func Presence(userid: String) -> String {
            return "presence_\(userid)"
        }
    }

    struct XMPP {
        struct Domain {
            static let User = "pvp.net"
            static let Room = "conference.pvp.net"
        }
        struct Resource {
            static let PC = "xiff"
            static let Mobile = "iOS"
        }
        static let DefaultGroup = "**Default"
        static let Unknown = "Unknown"
    }

    struct Segue {
        static let EnterChat = "EnterChat"
        static let SummonerModal = "SummonerModal"
    }
}
