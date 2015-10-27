//
//  LeagueChat.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 7..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import RealmSwift
import XMPPFramework

enum LeagueChatType {
    case Peer
    case Room
}

class LeagueChat : Object  {
    
    dynamic var id = ""
    dynamic var name = ""
    dynamic var unread = 0
    dynamic var timestamp = NSDate(timeIntervalSince1970: 1)
    let messages = List<LeagueMessage>()

    var lastMessage: LeagueMessage? {
        return messages.last
    }

    var type: LeagueChatType {
        if id.containsString("sum") {
            return .Peer
        } else {
            return .Room
        }
    }

    var jid: XMPPJID {
        switch(type) {
        case .Peer: return XMPPJID.jidWithUser(id, domain: Constants.XMPP.Domain.User, resource: nil)
        case .Room: return XMPPJID.jidWithUser(id, domain: Constants.XMPP.Domain.Room, resource: nil)
        }
    }

    convenience init(chatId: String, name: String) {
        self.init()
        self.id = chatId
        self.name = name
    }

    func addMessage(message: LeagueMessage, read: Bool = false) {
        self.messages.append(message)
        self.timestamp = message.timestamp
        if !read {
            self.unread++
        }
    }

    func clearUnread() {
        self.unread = 0
    }

}

// MARK : Realm Extensions

extension LeagueChat {
    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["type"]
    }

    func freeze() -> LeagueChat {
        return LeagueChat(chatId: id, name: name)
    }
}