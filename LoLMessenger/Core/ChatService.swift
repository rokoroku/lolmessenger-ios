//
//  ChatService.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 15..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import XMPPFramework
import RealmSwift

protocol ChatDelegate : class {
    func didEnterChatRoom(sender: ChatService, from: LeagueChat)
    func didFailToEnterChatRoom(sender: ChatService, from: LeagueChat)
    func didReceiveOccupantUpdate(sender: ChatService, from: LeagueChat, occupant: LeagueRoster)

    func didFailToDeliver(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData)
    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData)
    func didSendNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData)
}

extension ChatDelegate {
    func didEnterChatRoom(sender: ChatService, from: LeagueChat) { }
    func didFailToEnterChatRoom(sender: ChatService, from: LeagueChat) { }
    func didReceiveOccupantUpdate(sender: ChatService, from: LeagueChat, occupant: LeagueRoster) { }

    func didFailToDeliver(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) { }
    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) { }
    func didSendNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) { }
}

class ChatService : NSObject {
    
    var xmppService: XMPPService?
    var xmppMessageDeliveryRecipts: XMPPMessageDeliveryReceipts?

    private var roomDictionary = [String: XMPPRoom]()
    private var blacklistedChat = [String]()
    
    private var isActivated = false
    private var isPopulated = false
    private var delegates: [ChatDelegate] = []

    override private init () {

    }
    
    convenience init(xmppService: XMPPService) {
        self.init()
        self.xmppService = xmppService;
        self.activate()
    }
    
    func activate() {
        assert(!isActivated, "XMPPStream should not be activated")
        
        if let xmppService = xmppService, xmppStream = xmppService.stream() {
            xmppMessageDeliveryRecipts = XMPPMessageDeliveryReceipts(dispatchQueue: xmppService.dispatchQueue)
            xmppMessageDeliveryRecipts!.autoSendMessageDeliveryReceipts = true
            xmppMessageDeliveryRecipts!.autoSendMessageDeliveryRequests = true
            xmppMessageDeliveryRecipts!.activate(xmppStream)

            xmppStream.addDelegate(self, delegateQueue: xmppService.dispatchQueue)
            isActivated = true
        }
    }
    
    func deactivate() {
        if isActivated {
            for (_, xmppRoom) in roomDictionary {
                xmppRoom.removeDelegate(self)
                xmppRoom.deactivate()
            }
            xmppService?.stream()?.removeDelegate(self)
            xmppService = nil
            isActivated = false
        }
    }

    func isRoomJoined(roomId id: String) -> Bool {
        if let room = roomDictionary[id] {
            return room.isJoined
        }
        return false
    }

    func joinRoom(name: String) -> LeagueChat? {
        let trimmed = name.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
        let roomId = XMPPJID.jidWithUser("pu~" + trimmed.SHA1(), domain: Constants.XMPP.Domain.Room, resource: nil)
        joinRoomByJID(roomId)
        return getLeagueChatEntry(roomId.user, named: trimmed)
    }

    func joinRoomByJID(roomId: XMPPJID) {
        if let xmppService = xmppService {
            var room = roomDictionary[roomId.user]
            if room == nil {
                room = XMPPRoom(roomStorage: XMPPRoomLeagueRosterStorage(), jid: roomId)
                room?.addDelegate(self, delegateQueue: xmppService.dispatchQueue)
                room?.activate(xmppService.stream())
                roomDictionary[roomId.user] = room
            }
            if room!.isJoined == false && xmppService.myRosterElement != nil {
                let userElement = xmppService.myRosterElement!
                let nickname = userElement.username
                room!.joinRoomUsingNickname(nickname, history: nil)
            }
        }
    }

    func leaveRoom(roomJid: XMPPJID) -> Bool {
        if let room = roomDictionary.removeValueForKey(roomJid.user) {
            room.removeDelegate(self)
            room.leaveRoom()
            room.deactivate()
            getLeagueChatEntryByJID(roomJid)?.remove()
            return true
        }
        return false
    }

    func sendMessage(to: XMPPJID, msg: String) {
        if let xmppService = xmppService, xmppStream = xmppService.stream() {
            var message: XMPPMessage
            if to.domain == Constants.XMPP.Domain.Room {
                message = XMPPMessage(type: "groupchat", to: to)
            } else {
                message = XMPPMessage(type: "chat", to: to)
            }
            message.addBody(msg)
            xmppStream.sendElement(message)
        }
    }

    
    func addDelegate(delegate: ChatDelegate) {
        var contain = false
        for item in delegates {
            if item === delegate {
                contain = true
            }
        }
        if !contain {
            delegates.append(delegate)
        }
    }
    
    func removeDelegate(delegate: ChatDelegate) {
        for var i=0; i < delegates.count; i++ {
            let item = delegates[i]
            if item === delegate {
                delegates.removeAtIndex(i--)
            }
        }
    }

    func invokeDelegates(after: Double = 0, block: (ChatDelegate) -> Void) {
        for delegate in delegates {
            Async.main(after: after) {
                block(delegate)
            }
        }
    }

    func getLeagueChatEntry(jid: String, named: String? = nil) -> LeagueChat? {
        if xmppService == nil {
            return nil

        } else if let xmppService = xmppService, realm = xmppService.DB() {
            let result = realm.objects(LeagueChat.self).filter("id = '\(jid)'")
            if let storedChat = result.first {
                let _ = storedChat.messages.count
                return storedChat

            } else if let roster = xmppService.roster()?.getRosterByJID(jid) {
                do {
                    realm.beginWrite()
                    let createdChat = realm.create(LeagueChat.self, value: LeagueChat(chatId: jid, name: roster.username), update: true)
                    try realm.commitWrite()
                    return createdChat

                } catch _ {

                }
            } else if let name = named {
                do {
                    realm.beginWrite()
                    let createdChat = realm.create(LeagueChat.self, value: LeagueChat(chatId: jid, name: name), update: true)
                    try realm.commitWrite()
                    return createdChat
                } catch _ {
                    
                }
            }
        }
        return nil
    }

    func getRoomByJID(roomId: XMPPJID) -> XMPPRoom? {
        return roomDictionary[roomId.user]
    }

    func getOccupantsByJID(roomId: XMPPJID) -> [LeagueRoster]? {
        if let room = roomDictionary[roomId.user] {
            return room.getOccupants()
        }
        return nil
    }

    func getNumOfUnreadMessages() -> Int {
        if let xmppService = xmppService, realm = xmppService.DB() {
            return realm.objects(LeagueChat.self).reduce(0) { $0 + $1.unread }
        }
        return 0
    }

    func getLeagueChatEntryByJID(jid: XMPPJID) -> LeagueChat? {
        return getLeagueChatEntry(jid.user)
    }

    func getLeagueChatEntries() -> [LeagueChat]? {
        if let xmppService = xmppService, let realm = xmppService.DB() {
            return realm.objects(LeagueChat.self)
                .sorted("timestamp", ascending: false)
                .filter { $0.lastMessage != nil || $0.type != .Peer }
        }
        return nil
    }
}

// MARK : XMPPStreamDelegate

extension ChatService : XMPPStreamDelegate {
    @objc func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        self.getLeagueChatEntries()?.forEach { leagueChat in
            if leagueChat.type == .Room {
                let id = leagueChat.id
                Async.background(after: Double(random()%10)/10) {
                    self.joinRoomByJID(XMPPJID.jidWithUser(id, domain: Constants.XMPP.Domain.Room, resource: nil))
                }
            }
        }
    }

    @objc func xmppStream(sender: XMPPStream!, willReceiveMessage message: XMPPMessage!) -> XMPPMessage! {
        if message.body() != nil && message.from() != nil {
            if message.from().domain == Constants.XMPP.Domain.Room && message.body().characters.count > 100 {
                return nil
            }
            return message
        }
        return nil
    }

    @objc func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
        #if DEBUG
            print("didReceive \(message)")
        #endif

        if message.from().domain != Constants.XMPP.Domain.User {
            // skip messages such as endgame2145955503@sec.pvp.net/User
            // only handle peer-to-peer messages here.
            return

        } else if message.isSentMessageCarbon() && message.from().isEqualToJID(sender.myJID, options: XMPPJIDCompareUser) {
            // XEP-0280 SentMessageCarbon
            // XEP-0297 ForwardedMessage
            if let sentMessageCarbon = message.sentMessageCarbon(),
                let forwardedMessage = sentMessageCarbon.forwardedMessage() {
                    self.xmppStream(sender, didSendMessage: forwardedMessage)
            }

        } else if let xmppService = xmppService, leagueChat = getLeagueChatEntryByJID(message.from()) {
            let roster = xmppService.roster()?.getRosterByJID(message.from())
            if let leagueMessage = LeagueMessage(message: message, nick: roster?.username ?? leagueChat.name, isMine: false) {
                if message.type() == "error" {
                    if let lastMessage = leagueChat.messages.last {
                        if lastMessage.body == leagueMessage.body {
                            lastMessage.update {
                                lastMessage.isSent = false
                            }
                        }
                        let rawChat = leagueChat.freeze()
                        let rawMessage = leagueMessage.raw()
                        invokeDelegates {
                            delegate in delegate.didFailToDeliver(self, from: rawChat, message: rawMessage)
                        }
                    }
                } else {
                    var isActiveChat = false
                    if let chatController = UIApplication.topViewController() as? ChatViewController {
                        let isCurrentChat = chatController.chatJID?.isEqualToJID(leagueChat.jid, options: XMPPJIDCompareUser) ?? false
                        isActiveChat = isCurrentChat && UIApplication.isActive()
                    }

                    let updateBlock : dispatch_block_t = {
                        leagueChat.addMessage(leagueMessage, read: isActiveChat)
                        if let rosterName = roster?.username {
                            if rosterName != leagueChat.name {
                                leagueChat.name = rosterName
                            }
                        }
                    }

                    if !leagueChat.update(updateBlock) {
                        Async.background(after: 0.5) {
                            self.xmppStream(sender, didReceiveMessage: message)
                        }
                        #if DEBUG
                            let notification = NotificationUtils.create(title: "Error", body: "Retrying adding message \(message.body())", category: "nono")
                            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                        #endif
                        return;
                    }

                    let rawChat = leagueChat.freeze()
                    let rawMessage = leagueMessage.raw()

                    invokeDelegates {
                        delegate in delegate.didReceiveNewMessage(self, from: rawChat, message: rawMessage)
                    }

                    if !isActiveChat {
                        if !StoredProperties.AlarmDisabledJIDs.contains(leagueChat.id) && StoredProperties.Settings.notifyMessage.value {
                            let notification = NotificationUtils.create(leagueChat, message: leagueMessage)
                            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                        }
                    }
                    xmppService.updateBadge()
                }
            }
        }
    }

    @objc func xmppStream(sender: XMPPStream!, didSendMessage message: XMPPMessage!) {
        if let xmppService = xmppService, leagueChat = getLeagueChatEntryByJID(message.to()),
            let leagueMessage = LeagueMessage(message: message, nick: xmppService.myRosterElement!.username, isMine: true) {
                leagueChat.update {
                    leagueChat.addMessage(leagueMessage)
                }
                let rawChat = leagueChat.freeze()
                let rawMessage = leagueMessage.raw()
                invokeDelegates {
                    delegate in delegate.didSendNewMessage(self, from: rawChat, message: rawMessage)
                }
        }
    }

    @objc func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        if let xmppService = xmppService, let leagueMessage = LeagueMessage(message: message, nick: xmppService.myRosterElement!.username, isMine: true) {
            #if DEBUG
                print("didFailToSendMessage! " + leagueMessage.description)
            #endif
            if let chatEntry = getLeagueChatEntryByJID(message.from())?.freeze() {
                let rawMessage = leagueMessage.raw()
                invokeDelegates {
                    delegate in delegate.didFailToDeliver(self, from: chatEntry, message: rawMessage)
                }
            }
        }
    }
}

// MARK: XMPPRoom Delegate
extension ChatService: XMPPRoomDelegate {
    @objc func xmppRoomDidJoin(sender: XMPPRoom!) {
        #if DEBUG
            print("xmppRoomDidJoin: " + sender.roomJID.debugDescription)
        #endif
        if let xmppService = xmppService {
            xmppService.stream()?.resendMyPresence()
            roomDictionary[sender.roomJID.user] = sender
            if let chatEntry = getLeagueChatEntryByJID(sender.roomJID)?.freeze() {
                invokeDelegates {
                    delegate in delegate.didEnterChatRoom(self, from: chatEntry)
                }
            }
        }
    }

    @objc func xmppRoomDidLeave(sender: XMPPRoom!) {
        #if DEBUG
            print("xmppRoomDidLeave: " + sender.debugDescription)
        #endif
        roomDictionary.removeValueForKey(sender.roomJID.user)
    }

    @objc func xmppRoom(sender: XMPPRoom!, occupantDidJoin occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        if let chatEntry = getLeagueChatEntryByJID(sender.roomJID)?.freeze() {
            let occupant = LeagueRoster(jid: occupantJID, nickname: occupantJID.resource)
            occupant.parsePresence(presence)
            invokeDelegates {
                delegate in delegate.didReceiveOccupantUpdate(self, from: chatEntry, occupant: occupant)
            }
        }
    }

    @objc func xmppRoom(sender: XMPPRoom!, occupantDidLeave occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        if let chatEntry = getLeagueChatEntryByJID(sender.roomJID)?.freeze() {
            let occupant = LeagueRoster(jid: occupantJID, nickname: occupantJID.resource)
            occupant.parsePresence(presence)
            occupant.available = false
            occupant.show = .Unavailable
            invokeDelegates {
                delegate in delegate.didReceiveOccupantUpdate(self, from: chatEntry, occupant: occupant)
            }
        }
    }

    @objc func xmppRoom(sender: XMPPRoom!, occupantDidUpdate occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        if let chatEntry = getLeagueChatEntryByJID(sender.roomJID)?.freeze() {
            let occupant = LeagueRoster(jid: occupantJID, nickname: occupantJID.resource)
            occupant.parsePresence(presence)
            invokeDelegates {
                delegate in delegate.didReceiveOccupantUpdate(self, from: chatEntry, occupant: occupant)
            }
        }
    }

    @objc func xmppRoom(sender: XMPPRoom!, didReceiveMessage message: XMPPMessage!, fromOccupant occupantJID: XMPPJID!) {
        if let xmppService = xmppService, chatEntry = getLeagueChatEntryByJID(sender.roomJID), let leagueMessage = LeagueMessage(message: message) {
            if occupantJID.resource != xmppService.myRosterElement?.username {

                var isActiveChat = false
                if let chatController = UIApplication.topViewController() as? ChatViewController {
                    let isCurrentChat = chatController.chatJID?.isEqualToJID(chatEntry.jid, options: XMPPJIDCompareUser) ?? false
                    isActiveChat = isCurrentChat && UIApplication.isActive()
                }

                let updateBlock: dispatch_block_t = {
                    chatEntry.addMessage(leagueMessage, read: isActiveChat)
                }

                if !chatEntry.update(updateBlock) {
                    Async.background(after: 0.5) {
                        self.xmppRoom(sender, didReceiveMessage: message, fromOccupant: occupantJID)
                    }
                    #if DEBUG
                        let notification = NotificationUtils.create(title: "Error", body: "Retrying adding message \(message.body())", category: "nono")
                        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                    #endif
                }

                let rawChat = chatEntry.freeze()
                let rawMessage = leagueMessage.raw()
                invokeDelegates {
                    delegate in delegate.didReceiveNewMessage(self, from: rawChat, message: rawMessage)
                }

                if !isActiveChat {
                    if !StoredProperties.AlarmDisabledJIDs.contains(chatEntry.id) && StoredProperties.Settings.notifyMessage.value {
                        let notification = NotificationUtils.create(chatEntry, message: leagueMessage)
                        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                    }
                }
            }
        }
    }
}

extension XMPPRoom {

    func getNumOfOccupants() -> Int {
        if let storage = self.xmppRoomStorage as? XMPPRoomLeagueRosterStorage {
            return storage.numOfOccupants()
        }
        return 0
    }

    func getOccupantByName(name: String) -> LeagueRoster? {
        if let storage = self.xmppRoomStorage as? XMPPRoomLeagueRosterStorage {
            return storage.rosterByName(name)
        }
        return nil
    }

    func getOccupants() -> [LeagueRoster]? {
        if let storage = self.xmppRoomStorage as? XMPPRoomLeagueRosterStorage {
            return storage.rosterList()
//
//            return storage.occupants().flatMap { object -> LeagueRoster? in
//                if let occupant = object as? XMPPRoomOccupant {
//                    let roster = LeagueRoster(jid: occupant.roomJID(), nickname: occupant.nickname())
//                    roster.parsePresence(occupant.presence())
//                    if roster.show == .Unavailable {
//                        roster.show = .Chat
//                    }
//                    return roster
//                }
//                return nil
//            }
        }
        return nil
    }
}