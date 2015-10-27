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

    var xmppService: XMPPService!

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

        let xmppStream = xmppService.stream()

        xmppRoster.activate(xmppStream)
        xmppStream.addDelegate(self, delegateQueue: GCD.backgroundQueue())
        xmppRoster.addDelegate(self, delegateQueue: GCD.backgroundQueue())

        isActivated = true
    }

    func deactivate() {
        if isActivated {
            xmppService.stream().removeDelegate(self)
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
        var updatedRoster : LeagueRoster?
        if presence.isFrom(sender.myJID.bareJID()) {
            return

        } else if let roster = rosterDictionary[presence.from().user] {
            updatedRoster = roster
            updatedRoster!.parsePresence(presence)
        }

        if updatedRoster != nil && UIApplication.sharedApplication().applicationState == .Active {
            invokeDelegates {
                delegate in delegate.didReceiveRosterUpdate(self, from: updatedRoster!)
            }
        }
    }
}

// MARK : XMPPRosterDelegate
extension RosterService : XMPPRosterDelegate {
    @objc func xmppRoster(sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
        print("didReceivePresenceSubscriptionRequest: " + presence.description)
        xmppService.updateBadge()
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


