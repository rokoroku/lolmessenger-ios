//
//  LeagueMessage.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 15..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import RealmSwift
import XMPPFramework

class LeagueMessage : Object {
    
    dynamic var nick :String = ""
    dynamic var body :String = ""
    dynamic var isMine :Bool = false
    dynamic var isSent :Bool = false
    dynamic var timestamp = NSDate(timeIntervalSince1970: 1)

    struct RawData {
        var nick :String
        var body :String
        var isMine :Bool
        var isSent :Bool
        var timestamp :NSDate
    }

    convenience init?(message: XMPPMessage, nick: String? = nil, isMine: Bool = false) {
        self.init()

        if message.body() != nil {
            self.body = message.body()
        } else {
            return nil
        }

        var date : NSDate? = nil
        if let stamp = message.attributeStringValueForName("stamp") {
            date = stamp.parseDateTime()
        }
        if date == nil {
            date = NSDate()
        }
        self.timestamp = date!
        self.isMine = isMine
        self.isSent = false

        if(message.type() == "groupchat") {
            self.nick = message.from().resource

        } else if nick != nil {
            self.nick = nick!
        }
    }

    convenience init(nick: String, body: String, isMine: Bool, isSent: Bool, timestamp: NSDate) {
        self.init()
        self.nick = nick
        self.body = body
        self.isMine = isMine
        self.isSent = isSent
        self.timestamp = timestamp
    }

    func setSent() {
        self.isSent = true
    }

    func raw() -> RawData {
        return RawData(nick: nick, body: body, isMine: isMine, isSent: isSent, timestamp: timestamp)
    }

    func freeze() -> LeagueMessage {
        return LeagueMessage(nick: nick, body: body, isMine: isMine, isSent: isSent, timestamp: timestamp)
    }
}