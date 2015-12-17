//
//  RosterService.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 13..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import XMPPFramework
import RealmSwift

protocol RosterDelegate : class {
    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster)
    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster)
    func didReceiveFriendSubscriptionDenial(sender: RosterService, from: LeagueRoster)
}

extension RosterDelegate {
    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster) { }
    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster) { }
    func didReceiveFriendSubscriptionDenial(sender: RosterService, from: LeagueRoster) { }
}

enum RosterSort {
    case Name
    case Status
}

class RosterService : NSObject {

    var xmppService: XMPPService?

    var xmppRoster: XMPPRoster
    var xmppRosterStorage: XMPPRosterMemoryStorage
    
    private var rosterDictionary = [String: LeagueRoster]()
    private var blackListedIds = [String]()
    
    private var isActivated = false
    private var isPopulated = false
    private var delegates: [RosterDelegate] = []

    override private init () {
 
        // Setup roster
        //
        // The XMPPRoster handles the xmpp protocol stuff related to the roster.
        // The storage for the roster is abstracted.
        // So you can use any storage mechanism you want.
        // You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
        // or setup your own using raw SQLite, or create your own storage mechanism.
        // You can do it however you like! It's your application.
        // But you do need to provide the roster with some storage facility.
        
        xmppRosterStorage = XMPPRosterMemoryStorage()
        xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        
        xmppRoster.autoFetchRoster = true
        xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = true
        xmppRoster.autoClearAllUsersAndResources = false
    }
    
    convenience init (xmppService: XMPPService) {
        self.init()
        self.xmppService = xmppService
        self.activate()
    }
    
    func activate() {
        assert(!isActivated, "XMPPStream should not be activated")

        if let xmppService = xmppService, xmppStream = xmppService.stream() {
            xmppRoster.activate(xmppStream)
            xmppStream.addDelegate(self, delegateQueue: xmppService.dispatchQueue)
            xmppRoster.addDelegate(self, delegateQueue: xmppService.dispatchQueue)

            isActivated = true
        }
    }

    func deactivate() {
        if isActivated {
            xmppService?.stream()?.removeDelegate(self)
            xmppService = nil
            isActivated = false
        }
        xmppRoster.removeDelegate(self)
    }
    
    func getRosterByJID(jid: XMPPJID) -> LeagueRoster? {
        return rosterDictionary[jid.user]
    }

    func getRosterByJID(jid: String) -> LeagueRoster? {
        return rosterDictionary[jid]
    }

    func getRosterList(availableOnly: Bool = false, sortBy: RosterSort = .Name) -> [LeagueRoster]? {
        if rosterDictionary.isEmpty {
            return nil
        } else {
            let lazyValueCollection = rosterDictionary.values.filter { availableOnly ? $0.available : true }
            switch(sortBy) {
            case .Name: return lazyValueCollection.sort { $0.username < $1.username }
            case .Status: return lazyValueCollection.sort { $0.status.rawValue < $1.status.rawValue }
            }
        }
    }

    func addRoster(roster: LeagueRoster) {
        xmppRoster.addUser(roster.jid(), withNickname: roster.username, groups: [roster.group])
        xmppRoster.fetchRoster()
    }

    func removeRoster(roster: LeagueRoster) {
        rosterDictionary.removeValueForKey(roster.jid().user)
        xmppRoster.removeUser(roster.jid())
        xmppRoster.fetchRoster()
    }

    func setNote(roster: LeagueRoster, note: String) {
        xmppRoster.setNote(note, forUser: roster.jid())
    }

    func getNumOfSubscriptionRequests() -> Int {
        return 0
    }

    func addDelegate(delegate: RosterDelegate) {
        var contain = false;
        for item in delegates {
            if item === delegate {
                contain = true;
            }
        }
        if !contain {
            delegates.append(delegate)
        }
    }
    
    func removeDelegate(delegate: RosterDelegate) {
        for var i=0; i < delegates.count; i++ {
            let item = delegates[i]
            if item === delegate {
                delegates.removeAtIndex(i--)
            }
        }
    }

    func invokeDelegates(after: Double = 0, block: (RosterDelegate) -> Void) {
        for delegate in delegates {
            Async.main(after: after) {
                block(delegate)
            }
        }
    }

}

// MARK : XMPPStreamDelegate
extension RosterService : XMPPStreamDelegate {
    @objc func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        if presence.isFrom(sender.myJID, options: XMPPJIDCompareUser) {
            return
        }

        switch (presence.type()) {
        case "subscribe":
            break

        case "unsubscribe", "unsubscribed":
            if let roster = rosterDictionary.removeValueForKey(presence.from().user) {
                roster.parsePresence(presence)
                invokeDelegates {
                    delegate in delegate.didReceiveRosterUpdate(self, from: roster)
                }
            }
            break

        default:
            if let roster = rosterDictionary[presence.from().user] {
                roster.parsePresence(presence)
                invokeDelegates {
                    delegate in delegate.didReceiveRosterUpdate(self, from: roster)
                }
            } else {
                Async.background(after: 2) {
                    self.xmppStream(sender, didReceivePresence: presence)
                }
            }
        }
    }
}

// MARK : XMPPRosterDelegate
extension RosterService : XMPPRosterDelegate {

    private func notifySubscriptionRequest(roster: LeagueRoster) {
        if StoredProperties.Settings.notifySubscription.value {
            Async.main(after: 1.5) {

                let notification = NotificationUtils.create(
                    title: Localized("Buddy Request"),
                    body: Localized("The buddy %1$@ wants to add you to their list and see your presence online", args: roster.username),
                    category: Constants.Notification.Category.Subscribtion)
                NotificationUtils.schedule(notification)

                DialogUtils.alert(
                    Localized("Buddy Request"),
                    message: Localized("The buddy %1$@ wants to add you to their list and see your presence online", args: roster.username),
                    actions: [
                        UIAlertAction(title: Localized("OK"), style: .Default, handler: { _ in self.addRoster(roster) }),
                        UIAlertAction(title: Localized("NO"), style: .Cancel, handler: { _ in self.removeRoster(roster) })
                    ])

                self.invokeDelegates {
                    delegate in delegate.didReceiveFriendSubscription(self, from: roster)
                }
            }
        }
    }

    @objc func xmppRoster(sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
        #if DEBUG
            print("didReceivePresenceSubscriptionRequest: " + presence.description)
        #endif
        if let xmppService = xmppService, jid = presence.from() {
            if let name = presence.attributeStringValueForName("name") {
                let summoner = LeagueRoster(jid: jid, nickname: name)
                notifySubscriptionRequest(summoner)

            } else {
                RiotAPI.getSummonerById(summonerId: jid.user, region: xmppService.region!) { summoner in
                    if let summoner = summoner {
                        self.notifySubscriptionRequest(summoner)
                    }
                }
            }
        }
    }

    @objc func xmppRosterDidBeginPopulating(sender: XMPPRoster!, withVersion version: String!) {
        isPopulated = false
    }
    
    @objc func xmppRosterDidEndPopulating(sender: XMPPRoster!) {
        isPopulated = true
    }
    
    @objc func xmppRoster(sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) {
        let received = LeagueRoster(rosterElement: item)
        if let original = rosterDictionary[received.userid] {
            original.username = received.username
            original.group = received.group
            original.note = received.note
        } else {
            rosterDictionary[received.userid] = received
        }
    }

    
}

extension XMPPRoster {
    public func setNote(note: String?, forUser jid: XMPPJID) {
        let item = DDXMLElement(name: "item")
        item.addAttributeWithName("jid", stringValue: jid.bare())
        item.addChild(DDXMLElement(name: "note", stringValue: note))

        let query = DDXMLElement(name: "query", xmlns: "jabber:iq:roster")
        query.addChild(item)

        let iq = XMPPIQ(type: "set", child: query)
        xmppStream.sendElement(iq)
    }
}
