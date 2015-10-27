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
    func didFailToDeliver(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData)
    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData)
    func didSendNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData)
}
extension ChatDelegate {
    func didEnterChatRoom(sender: ChatService, from: LeagueChat) { }
    func didFailToDeliver(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) { }
    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) { }
    func didSendNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) { }
}

class ChatService : NSObject {
    
    var xmppService: XMPPService!
    var xmppMessageDeliveryRecipts: XMPPMessageDeliveryReceipts!

    private var chatDictionary = [String: LeagueChat]()
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
        
        let xmppStream = xmppService.stream()

        xmppMessageDeliveryRecipts = XMPPMessageDeliveryReceipts(dispatchQueue: GCD.backgroundQueue())
        xmppMessageDeliveryRecipts!.autoSendMessageDeliveryReceipts = true
        xmppMessageDeliveryRecipts!.autoSendMessageDeliveryRequests = true
        xmppMessageDeliveryRecipts!.activate(xmppStream)

        xmppStream.addDelegate(self, delegateQueue: GCD.backgroundQueue())
        isActivated = true
    }
    
    func deactivate() {
        if isActivated {
            for (_, xmppRoom) in roomDictionary {
                xmppRoom.removeDelegate(self)
                xmppRoom.deactivate()
            }
            xmppService.stream().removeDelegate(self)
            xmppService = nil
            isActivated = false
        }
    }
    
    func joinRoom(roomJid: XMPPJID) -> Bool {
        let xmppStream = xmppService.stream()
        if roomDictionary[roomJid.user] == nil {
            let xmppRoom = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: roomJid)
            xmppRoom.activate(xmppStream)
            xmppRoom.addDelegate(self, delegateQueue: GCD.backgroundQueue())
            xmppRoom.joinRoomUsingNickname(xmppStream.myPresence.nick(), history: nil)
        }
        return true
    }
    
    func leaveRoom(roomJid: XMPPJID) -> Bool {
        if let room = roomDictionary.removeValueForKey(roomJid.bare()) {
            room.leaveRoom()
            room.removeDelegate(self)
            room.deactivate()
            return true
        }
        return false
    }

    func sendMessage(to: XMPPJID, msg: String) {
        let xmppStream = xmppService.stream()
        var message: XMPPMessage
        if to.domain == Constants.XMPP.Domain.Room {
            message = XMPPMessage(type: "groupchat", to: to)
        } else {
            message = XMPPMessage(type: "chat", to: to)
        }
        message.addBody(msg)
        xmppStream.sendElement(message)
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

    func getLeagueChatEntry(jid: String) -> LeagueChat? {

        let realm = xmppService.db()
        let result = realm.objects(LeagueChat.self).filter("id = '\(jid)'")
        if let storedChat = result.first {
            let _ = storedChat.messages.count
            return storedChat

        } else {
            if let roster = xmppService.roster().getRosterByJID(jid) {
                do {
                    realm.beginWrite()
                    let createdChat = realm.create(LeagueChat.self, value: LeagueChat(chatId: jid, name: roster.username))
                    try realm.commitWrite()
                    return createdChat

                } catch _ {

                }

            } else {
                // TODO: sent to room
            }
        }
        return nil
    }

    func getNumOfUnreadMessages() -> Int {
        return xmppService.db().objects(LeagueChat.self).reduce(0) { $0 + $1.unread }
    }

    func getLeagueChatEntryByJID(jid: XMPPJID) -> LeagueChat? {
        return getLeagueChatEntry(jid.user)
    }

    func getLeagueChatEntries() -> [LeagueChat]? {
        return xmppService.db().objects(LeagueChat).sorted("timestamp", ascending: false).filter{ $0.lastMessage != nil }
    }
}

// MARK : XMPPStreamDelegate

extension ChatService : XMPPStreamDelegate {
    @objc func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
        print("didReceive \(message)")
        if let leagueChat = getLeagueChatEntryByJID(message.from()) {
            if let leagueMessage = LeagueMessage(message: message, nick: leagueChat.name, isMine: false) {
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
                        isActiveChat = isCurrentChat && !UIApplication.isActive()
                    }

                    leagueChat.update {
                        leagueChat.addMessage(leagueMessage, read: isActiveChat)
                    }

                    let rawChat = leagueChat.freeze()
                    let rawMessage = leagueMessage.raw()
                    invokeDelegates {
                        delegate in
                        print("invokeDelegate \(delegate)")
                        delegate.didReceiveNewMessage(self, from: rawChat, message: rawMessage)
                    }

                    if !isActiveChat {
                        let notification = NotificationUtils.create(leagueChat, message: leagueMessage)
                        UIApplication.sharedApplication().scheduleLocalNotification(notification)
                    }

                    xmppService.updateBadge()
                }
            }
        }
        else if message.isSentMessageCarbon() && message.from().isEqualToJID(sender.myJID, options: XMPPJIDCompareUser) {
            // XEP-0280 SentMessageCarbon
            // XEP-0297 ForwardedMessage
            if let sentMessageCarbon = message.sentMessageCarbon(),
                let forwardedMessage = sentMessageCarbon.forwardedMessage() {
                    self.xmppStream(sender, didSendMessage: forwardedMessage)
            }
        }
    }

    @objc func xmppStream(sender: XMPPStream!, didSendMessage message: XMPPMessage!) {
        if let leagueChat = getLeagueChatEntryByJID(message.to()),
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
        if let leagueMessage = LeagueMessage(message: message, nick: xmppService.myRosterElement!.username, isMine: true) {
            print("didFailToSendMessage! " + leagueMessage.description)
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
        roomDictionary[sender.roomJID.user] = sender
    }
    @objc func xmppRoomDidLeave(sender: XMPPRoom!) {
        roomDictionary.removeValueForKey(sender.roomJID.user)
    }
    @objc func xmppRoom(sender: XMPPRoom!, occupantDidJoin occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        
    }
    @objc func xmppRoom(sender: XMPPRoom!, occupantDidLeave occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        
    }
    @objc func xmppRoom(sender: XMPPRoom!, occupantDidUpdate occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        
    }
    @objc func xmppRoom(sender: XMPPRoom!, didReceiveMessage message: XMPPMessage!, fromOccupant occupantJID: XMPPJID!) {
        
    }
    
}