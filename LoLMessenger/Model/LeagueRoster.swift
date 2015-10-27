//
//  LeaguePresence.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 2..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import RealmSwift
import XMPPFramework

enum LeagueState : Int8 {
    // chat
    case Online
    case HostingGame

    // dnd
    case InQueue
    case SelectingChampion
    case InGame
    case Spectating

    // away
    case Away

    // unavailable
    case Offline
    case Unknown
}

class LeagueRoster {

    //Roster Field
    var userid: String
    var username: String
    var group: String

    //XMPP IQ Field
    var note: String?
    
    //XMPP Presense Field
    var available: Bool = false
    var subscribed: Bool = false
    var priority: Int?
    var show: XMPPPresence.Show = .Unknown {
        didSet {
            available = show != .Unknown
        }
    }

    //League Presence Field
    var level: Int?
    var profileIcon: Int?
    var status: LeagueState = .Unknown {
        didSet {
            available = status != LeagueState.Offline
        }
    }
    var championMasteryScore : Int?
    var statusMsg: String?
    var normalWins: Int?
    var rankedWins: Int?
    var rankedLeagueName: String?
    var rankedLeagueDivision: String?
    var rankedLeagueTier: String?
    var rankedLeagueQueue: String?
    var gameQueueType: String?
    var gameStatus: String?
    var skinName: String?
    var timeStamp: Int?
    
    init(rosterElement: DDXMLElement) {
        self.userid = XMPPJID.jidWithString(rosterElement.attributeStringValueForName("jid")).user
        self.username = rosterElement.attributeStringValueForName("name", withDefaultValue: Constants.XMPP.Unknown)
        self.group = rosterElement.getElementStringValue("group", defaultValue: Constants.XMPP.DefaultGroup)!
        self.note = rosterElement.getElementStringValue("note")
    }

    init(jid: XMPPJID, nickname: String?, group: String?) {
        self.userid = jid.user
        self.username = nickname ?? Constants.XMPP.Unknown
        self.group = group != nil ? group! : Constants.XMPP.DefaultGroup
    }

    func jid() -> XMPPJID {
        return XMPPJID.jidWithUser(userid, domain: Constants.XMPP.Domain.User, resource: Constants.XMPP.Resource.Mobile)
    }

    func getDisplayStatus() -> String {
        switch(status) {
        case .Online, .Away:
            if let statusMessage = statusMsg {
                if !statusMessage.stringByReplacingOccurrencesOfString(" ", withString: "").isEmpty {
                    return statusMessage
                } else {
                    return status == .Online ? "Online" : "Away"
                }
            }
        case .HostingGame:
            return "Hosting Game"

        case .InQueue:
            return "In Queue"

        case .SelectingChampion:
            return "Selecting Champion"

        case .InGame:
            return "In Game"

        case .Spectating:
            return "Hosting Game"

        case .Offline:
            return "Offline"

        default:
            break
        }

        switch(show) {
        case .Chat: return "Online"
        case .Away: return "Away"
        case .Dnd: return "In Game"
        default: break
        }
        return "Offline"
    }

    func parsePresence(xmppPresence: XMPPPresence) {
        if xmppPresence.from() != nil {
            userid = xmppPresence.from().user
        }

        show = xmppPresence.showType()
        switch (show) {
            case .Chat: status = .Online; break;
            case .Away: status = .Away; break;
            case .Dnd: status = .InGame; break;
            default: status = .Unknown;
        }

        if let type = xmppPresence.type() {
            if type == "unavailable" {
                available = false
                status = .Offline
                show = .Unknown
                return;
            }
        }

        if let statusElement = xmppPresence.elementForName("status") {
            available = true
            do {
                let element = try DDXMLElement(XMLString: statusElement.stringValue().decodeXML())
                level = element.getElementIntValue("level")
                profileIcon = element.getElementIntValue("profileIcon")
                championMasteryScore = element.getElementIntValue("championMasteryScore")
                normalWins = element.getElementIntValue("wins")
                rankedWins = element.getElementIntValue("rankedWins")
                rankedLeagueName = element.getElementStringValue("rankedLeagueName")
                rankedLeagueDivision = element.getElementStringValue("rankedLeagueDivision")
                rankedLeagueTier = element.getElementStringValue("rankedLeagueTier")
                rankedLeagueQueue = element.getElementStringValue("rankedLeagueQueue")
                skinName = element.getElementStringValue("skinname")
                statusMsg = element.getElementStringValue("statusMsg")
                gameQueueType = element.getElementStringValue("gameQueueType")
                gameStatus = element.getElementStringValue("gameStatus")
                timeStamp = element.getElementIntValue("timeStamp")
            } catch _ {

            }
        }

        if let _ = gameStatus {
            let lowercasedGameStatus = gameStatus!.lowercaseString
            if show == .Chat && lowercasedGameStatus.containsString("hosting") {
                status = .HostingGame
            } else if show == .Dnd {
                if lowercasedGameStatus.containsString("queue") {
                    status = .InQueue
                } else if lowercasedGameStatus.containsString("champion") {
                    status = .SelectingChampion
                } else if lowercasedGameStatus.containsString("ingame") {
                    status = .InGame
                } else if lowercasedGameStatus.containsString("spectating") {
                    status = .Spectating
                }
            }
        }
    }

    func getPresenceElement() -> XMPPPresence {
        let presence = XMPPPresence(type: available ? "available" : "unavailable")
        if available {
            var showValue : String?
            switch(show) {
                case .Chat: showValue = "chat"; break;
                case .Away: showValue = "away"; break;
                case .Dnd: showValue = "dnd"; break;
                case .Unknown: showValue = nil; break;
            }

            if showValue != nil {
                presence.addChild(DDXMLElement(name: "show", stringValue: showValue))
            }

            if let status = getStatusElement() {
                presence.addChild(status)
            }
        }
        presence.addChild(DDXMLElement(name: "nick", stringValue: username))

        if let priority = priority {
            if let priorityElement = presence.elementForName("priority") {
                priorityElement.setStringValue(String(priority))
            } else {
                presence.addChild(DDXMLElement(name: "priority", stringValue: String(priority)))
            }
        }
        return presence
    }

    func getNumericUserid() -> Int? {
        return Int(userid.substringFromIndex(userid.startIndex.advancedBy(3)))
    }
    
    func getStatusElement() -> DDXMLElement? {
        let body = DDXMLElement(name: "body")

        body.addChild(DDXMLElement(name: "level", numberValue: level))
        body.addChild(DDXMLElement(name: "profileIcon", numberValue: profileIcon))
        body.addChild(DDXMLElement(name: "championMasteryScore", numberValue: championMasteryScore))
        body.addChild(DDXMLElement(name: "wins", numberValue: normalWins))
        body.addChild(DDXMLElement(name: "rankedWins", numberValue: rankedWins))
        body.addChild(DDXMLElement(name: "rankedLeagueName", stringValue: rankedLeagueName))
        body.addChild(DDXMLElement(name: "rankedLeagueDivision", stringValue: rankedLeagueDivision))
        body.addChild(DDXMLElement(name: "rankedLeagueTier", stringValue: rankedLeagueTier))
        body.addChild(DDXMLElement(name: "rankedLeagueQueue", stringValue: rankedLeagueQueue))
        body.addChild(DDXMLElement(name: "skinName", stringValue: skinName))
        body.addChild(DDXMLElement(name: "statusMsg", stringValue: statusMsg))
        body.addChild(DDXMLElement(name: "gameQueueType", stringValue: gameQueueType))
        body.addChild(DDXMLElement(name: "gameStatus", stringValue: gameStatus))
        body.addChild(DDXMLElement(name: "timeStamp", numberValue: timeStamp))

        return DDXMLElement(name: "status", stringValue: body.XMLString())
    }
    
    var description: String {
        return "<user jid=\"\(userid)\" name=\"\(username)\" group=\"\(group)\">" + getPresenceElement().XMLString() + "</user>"
    }

}
