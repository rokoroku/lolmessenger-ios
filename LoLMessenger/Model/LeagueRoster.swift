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
    case InTeamSelect
    case InChampionSelect
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
    var show: PresenceShow = .Unavailable {
        didSet {
            available = show != .Unavailable
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

    //Properties
    private var currentGameQueueString: String? {
        if let type = gameQueueType {
            if type.containsString("ARAM") || type.containsString("NORMAL") || type.containsString("UNRANKED") { return "Normal" }
            else if type.containsString("BOT") { return "Co-op" }
            else if type.containsString("RANKED") { return "Ranked" }
            else if type.containsString("NONE") { return  "Custom" }
        }
        return nil
    }

    private var currentGameType: String? {
        if let type = gameQueueType {
            if type.containsString("ARAM") { return "ARAM" }
            else if type.containsString("5x5") || type.containsString("NORMAL") { return "Summoner's Rift" }
            else if type.containsString("3x3") { return "Twisted Treeline" }
        }
        return nil
    }

    var elapsedTime: NSTimeInterval? {
        if let gameStartedAt = timeStamp {
            return NSDate().timeIntervalSince1970 - NSTimeInterval(gameStartedAt/1000)
        }
        return nil
    }

    init(rosterElement: DDXMLElement) {
        self.userid = XMPPJID.jidWithString(rosterElement.attributeStringValueForName("jid")).user
        self.username = rosterElement.attributeStringValueForName("name", withDefaultValue: Constants.XMPP.Unknown)
        self.subscribed = rosterElement.attributeStringValueForName("subscription", withDefaultValue: "none") != "none"
        self.group = rosterElement.getElementStringValue("group", defaultValue: Constants.XMPP.DefaultGroup)!
        self.note = rosterElement.getElementStringValue("note")
    }


    init(numberId id: Int, nickname: String?, group: String? = nil) {
        self.userid = "sum\(id)"
        self.username = nickname ?? Constants.XMPP.Unknown
        self.group = group != nil ? group! : Constants.XMPP.DefaultGroup
    }

    init(stringId id: String, nickname: String?, group: String? = nil) {
        if id.containsString("sum") {
            self.userid = id
        } else {
            self.userid = "sum" + id
        }
        self.username = nickname ?? Constants.XMPP.Unknown
        self.group = group != nil ? group! : Constants.XMPP.DefaultGroup
    }

    init(jid: XMPPJID, nickname: String?, group: String? = nil) {
        self.userid = jid.user
        self.username = nickname ?? Constants.XMPP.Unknown
        self.group = group != nil ? group! : Constants.XMPP.DefaultGroup
    }

    func jid() -> XMPPJID {
        return XMPPJID.jidWithUser(userid, domain: Constants.XMPP.Domain.User, resource: Constants.XMPP.Resource.Mobile)
    }

    func getDisplayColor() -> UIColor {
        switch(show) {
        case .Chat: return Theme.GreenColor
        case .Away: return Theme.RedColor
        case .Dnd: return Theme.YellowColor
        default: return Theme.TextColorDisabled
        }
    }

    func getCurrentGameStatus() -> String? {
        if status == .InGame {
            if let queue = currentGameQueueString {
                if let type = currentGameType {
                    if let champion = skinName { return "\(type) (\(queue)) - \(champion)" }
                    else { return "\(type) (\(queue))" }
                }
                else if let champion = skinName {
                    return "\(queue) Game - \(champion)"
                } else {
                    return "\(queue) Game "
                }
            } else if let champion = skinName {
                return "In Game - \(champion)"
            } else {
                return "In Game"
            }
        }
        return nil
    }

    func getDisplayStatus(showStatusMessage: Bool = true) -> String {

        switch(status) {
        case .Online, .Away:
            if let statusMessage = statusMsg {
                if showStatusMessage && !statusMessage.stringByReplacingOccurrencesOfString(" ", withString: "").isEmpty {
                    return statusMessage
                } else {
                    return status == .Online ? "Online" : "Away"
                }
            }
        case .HostingGame:
            var queueType = ""
            if let type = gameStatus {
                if type == "inTeamBuilder" { return "In Team Builder" }
                else if type.containsString("Normal") { queueType = "Normal" }
                else if type.containsString("Ranked") { queueType = "Ranked" }
                else if type.containsString("CoopVsAI") { queueType = "Co-op" }
                else if type.containsString("Practice") { queueType = "Practice" }
            }
            return "Hosting a \(queueType) Game"

        case .InTeamSelect:
            return "In Team Select"

        case .InQueue:
            return "In Queue"

        case .InChampionSelect:
            return "In Champion Select"

        case .InGame:
            return "In Game"

        case .Spectating:
            return "Spectating"

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

        if xmppPresence.childCount() == 0 {
            show = .Chat
            status = .Unknown
            return
        }

        show = xmppPresence.showType()
        switch (show) {
        case .Chat:
            status = .Online
            break
        case .Away:
            status = .Away
            break
        case .Dnd:
            status = .InGame
            break
        default:
            status = .Unknown
        }
        if show != .Unavailable {
            subscribed = true
        }

        if let type = xmppPresence.type() {
            if type == "unavailable" {
                show = .Unavailable
                status = .Offline
                available = false
                return
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
            if show == .Chat {
                if lowercasedGameStatus.containsString("hosting") {
                    status = .HostingGame
                } else if lowercasedGameStatus.containsString("team") {
                    status = .InTeamSelect
                }
            } else if show == .Dnd {
                if lowercasedGameStatus.containsString("queue") {
                    status = .InQueue
                } else if lowercasedGameStatus.containsString("champion") {
                    status = .InChampionSelect
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
                default: showValue = nil; break;
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

    func getNumericUserId() -> Int? {
        return Int(userid.substringFromIndex(userid.startIndex.advancedBy(3)))
    }

    func getStatusIcon() -> UIImage? {
        return show.icon()
    }

    func getProfileIcon() -> UIImage? {
        if let iconId = profileIcon {
            return UIImage(named: "profile_\(iconId)")
        } else {
            return UIImage(named: "profile_unknown")
        }
    }

    func getStatusElement() -> DDXMLElement? {
        let body = DDXMLElement(name: "body")

        body.addChild(DDXMLElement(name: "level", numberValue: level))
        body.addChild(DDXMLElement(name: "profileIcon", numberValue: profileIcon))
        body.addChild(DDXMLElement(name: "statusMsg", stringValue: statusMsg))
        body.addChild(DDXMLElement(name: "championMasteryScore", numberValue: championMasteryScore))
        body.addChild(DDXMLElement(name: "wins", numberValue: normalWins))
        body.addChild(DDXMLElement(name: "rankedWins", numberValue: rankedWins))
        body.addChild(DDXMLElement(name: "rankedLeagueName", stringValue: rankedLeagueName))
        body.addChild(DDXMLElement(name: "rankedLeagueDivision", stringValue: rankedLeagueDivision))
        body.addChild(DDXMLElement(name: "rankedLeagueTier", stringValue: rankedLeagueTier))
        body.addChild(DDXMLElement(name: "rankedLeagueQueue", stringValue: rankedLeagueQueue))
        //body.addChild(DDXMLElement(name: "skinName", stringValue: skinName))
        //body.addChild(DDXMLElement(name: "gameQueueType", stringValue: gameQueueType))
        //body.addChild(DDXMLElement(name: "gameStatus", stringValue: gameStatus))
        //body.addChild(DDXMLElement(name: "timeStamp", numberValue: timeStamp))

        return DDXMLElement(name: "status", stringValue: body.XMLString())
    }
    
    var description: String {
        return "<user jid=\"\(userid)\" name=\"\(username)\" group=\"\(group)\">" + getPresenceElement().XMLString() + "</user>"
    }

}
