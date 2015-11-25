//
//  XMPPRoomLeagueRosterStorage.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 18..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import XMPPFramework

class XMPPRoomLeagueRosterStorage : XMPPRoomMemoryStorage {

    override func configureWithParent(aParent: XMPPRoom!, queue: dispatch_queue_t!) -> Bool {
        let result = super.configureWithParent(aParent, queue: queue)
        aParent.addDelegate(self, delegateQueue: queue)
        return result
    }

    private var rosterTable = [String:LeagueRoster]()

    func rosterByName(name: String) -> LeagueRoster? {
        return rosterTable[name]
    }

    func rosterList() -> [LeagueRoster] {
        return rosterTable.values.map { $0 }
    }

    func numOfOccupants() -> Int {
        return rosterTable.count
    }
}

extension XMPPRoomLeagueRosterStorage : XMPPRoomMemoryStorageDelegate {
    @objc func xmppRoomMemoryStorage(sender: XMPPRoomMemoryStorage!, occupantDidJoin occupant: XMPPRoomOccupantMemoryStorageObject!, atIndex index: UInt, inArray allOccupants: [AnyObject]!) {

        if occupant.nickname != nil {
            let roster = LeagueRoster(jid: occupant.roomJID, nickname: occupant.nickname)
            roster.parsePresence(occupant.presence)

            if roster.show == .Unavailable {
                roster.show = .Chat
            }
            rosterTable[occupant.nickname] = roster
        }

    }

    @objc func xmppRoomMemoryStorage(sender: XMPPRoomMemoryStorage!, occupantDidLeave occupant: XMPPRoomOccupantMemoryStorageObject!, atIndex index: UInt, fromArray allOccupants: [AnyObject]!) {

        if occupant.nickname != nil {
            rosterTable.removeValueForKey(occupant.nickname)
        }
    }

    @objc func xmppRoomMemoryStorage(sender: XMPPRoomMemoryStorage!, occupantDidUpdate occupant: XMPPRoomOccupantMemoryStorageObject!, fromIndex oldIndex: UInt, toIndex newIndex: UInt, inArray allOccupants: [AnyObject]!) {

        if let roster = rosterTable[occupant.nickname] {
            roster.parsePresence(occupant.presence)
            if roster.show == .Unavailable {
                roster.show = .Chat
            }
        }

    }

}
