//
// XMPPService.swift
// XMPPService
//
// Created by 김영록 on 2015. 10. 1..
// Copyright (c) 2015 rokoroku. All rights reserved.
//

import XMPPFramework
import RealmSwift

protocol XMPPConnectionDelegate : class {
    func onConnected(sender: XMPPService)
    func onAuthenticated(sender: XMPPService)
    func onAuthenticationFailed(sender: XMPPService)
    func onDisconnected(sender: XMPPService, error: ErrorType?)
}

enum XMPPConnectionError: ErrorType {
    case WrongCredential
    case NetworkUnavailable
    case SocketTimeout
}

class XMPPService : NSObject {

    // This approach supports lazy initialization because
    // Swift lazily initializes class constants (and variables),
    // and is thread safe by the definition of let.
    static let sharedInstance = XMPPService()

    var region: LeagueServer?
    var myRosterElement: LeagueRoster?

    private var chatService: ChatService?
    private var rosterService: RosterService?

    private var realmUnlocked = false
    private var dedicatedRealm: RealmWrapper?
    private var realmCache = [Int: Weak<Realm>]()
    private var realmConfig: Realm.Configuration? {
        var config = Realm.Configuration()
        if let path = xmppStream?.myJID.user {
            // Use the default directory, but replace the filename with the username
            config.path = NSURL.fileURLWithPath(config.path!)
                .URLByDeletingLastPathComponent?
                .URLByAppendingPathComponent(path)
                .URLByAppendingPathExtension("realm")
                .path

            if StoredProperties.Settings.backgroundEnabled {
                if !realmUnlocked && UIApplication.sharedApplication().applicationState == .Background {
                    // unlock realm lock file so that realm can be accessible in background
                    let allRealmRelatedFiles = [
                        config.path!,
                        config.path!.stringByAppendingString(".lock"),
                        config.path!.stringByAppendingString(".log"),
                        config.path!.stringByAppendingString(".log_a"),
                        config.path!.stringByAppendingString(".log_b")]
                    allRealmRelatedFiles.forEach {
                        let _ = try? NSFileManager.defaultManager().setAttributes([NSFileProtectionKey: NSFileProtectionNone], ofItemAtPath: $0)
                    }
                    realmUnlocked = true
                } 
            }
            return config
        }
        return nil
    }

    private var xmppStream: XMPPStream?
    private var xmppReconnect: XMPPReconnect?
    private var xmppAutoPing: XMPPAutoPing?

    private var customCertEvaluation: Bool?
    private var delegates: [XMPPConnectionDelegate] = []

    var isXmppConnected: Bool {
        return xmppStream?.isConnected() ?? false
    }

    var isAuthenticated: Bool {
        return isXmppConnected && xmppStream?.isAuthenticated() ?? false
    }

    lazy var dispatchQueue: dispatch_queue_t = {
        let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0);
        return dispatch_queue_create("xmpp-service-queue", attr)
    }()

    // MARK: Constructor
    override init() {
        super.init()
    }

    deinit {
        if(xmppStream != nil) {
            teardownStream()
        }
    }

    // MARK: Function
    private func setupStream() {

        // Setup xmpp stream
        //
        // The XMPPStream is the base class for all activity.
        // Everything else plugs into the xmppStream, such as modules/extensions and delegates.

        xmppStream = XMPPStream()
        
        // Want xmpp to run in the background?
        //
        // P.S. - The simulator doesn't support backgrounding yet.
        //        When you try to set the associated property on the simulator, it simply fails.
        //        And when you background an app on the simulator,
        //        it just queues network traffic til the app is foregrounded again.
        //        We are patiently waiting for a fix from Apple.
        //        If you do enableBackgroundingOnSocket on the simulator,
        //        you will simply see an error message from the xmpp stack when it fails to set the property.
        #if !TARGET_IPHONE_SIMULATOR
            xmppStream!.enableBackgroundingOnSocket = true
        #endif

        // Setup reconnect
        //
        // The XMPPReconnect module monitors for "accidental disconnections" and
        // automatically reconnects the stream for you.
        // There's a bunch more information in the XMPPReconnect header file.

        xmppReconnect = XMPPReconnect()
        xmppReconnect?.usesOldSchoolSecureConnect = true
        xmppReconnect?.addDelegate(self, delegateQueue: GCD.mainQueue())

        xmppAutoPing = XMPPAutoPing()
        xmppAutoPing?.addDelegate(self, delegateQueue: GCD.mainQueue())

        // Activate xmpp modules
        xmppReconnect?.activate(xmppStream)
        xmppAutoPing?.activate(xmppStream)

        // Add ourself as a delegate to anything we may be interested in
        xmppStream?.addDelegate(self, delegateQueue: GCD.mainQueue())
        
        // You may need to alter these settings depending on the server you're connecting to
        customCertEvaluation = true

        // Create submodule service
        rosterService = RosterService(xmppService: self)
        chatService = ChatService(xmppService: self)
    }

    private func teardownStream() {
        #if DEBUG
            print("Tearing down the XMPP stream...")
        #endif
        xmppStream?.removeDelegate(self)
        
        xmppReconnect?.deactivate()
        rosterService?.deactivate()
        chatService?.deactivate()
        xmppAutoPing?.deactivate()
        xmppStream?.disconnect()

        xmppStream = nil
        xmppAutoPing = nil
        xmppReconnect = nil
        rosterService = nil
        chatService = nil
    }

    // MARK: Connect / Disconnect
    func connect(leagueServer: LeagueServer) -> Bool {
        if let stream = xmppStream {
            if stream.isConnected() {
                return true
            }
        } else {
            setupStream()
        }

        do {
            xmppStream?.hostPort = 5223
            xmppStream?.hostName = leagueServer.host
            xmppStream?.myJID = XMPPJID.jidWithString(Constants.XMPP.Domain.User, resource: Constants.XMPP.Resource.Mobile)

            try xmppStream?.oldSchoolSecureConnectWithTimeout(3000)

        } catch let error as NSError {
            print(error.description)
            region = nil
            return false
        }

        region = leagueServer
        return true;
    }

    func login(username: String, password: String) -> Bool {
        do {
            let token = XMPPPlainAuthentication(stream: xmppStream!, username: username, password: "AIR_" + password)
            try xmppStream?.authenticate(token)
        } catch let error as NSError {
            print(error.description)
            return false;
        }
        return true;
    }

    func disconnect() {
        if xmppStream != nil {
            teardownStream()
        }
    }

    func sendPresence(presence: XMPPPresence) {
        StoredProperties.Presences.put(xmppStream!.myJID.user, presence: presence)
        xmppStream?.sendElement(presence)
    }

    func updateBadge() {
        if isAuthenticated {
            let badge = chat()!.getNumOfUnreadMessages() + roster()!.getNumOfSubscriptionRequests()
            UIApplication.sharedApplication().applicationIconBadgeNumber = badge
        } else {
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        }
    }

    func roster() -> RosterService? {
        return rosterService
    }
    
    func chat() -> ChatService? {
        return chatService
    }
    
    func stream() -> XMPPStream? {
        return xmppStream
    }

    func DB(readOnly: Bool = false) -> Realm? {
        assert(xmppStream != nil)

        var realm: Realm?
        let hash = NSThread.currentThread().description.hash
        if let cached = realmCache[hash] {
            if let cachedRealm = cached.value {
                if !cachedRealm.inWriteTransaction {
                    realm = cachedRealm
                }
            } else {
                realmCache.filter{(_, value) in value.value == nil}.forEach {
                    realmCache.removeValueForKey($0.0)
                }
            }
        }
        if realm == nil {
            if var config = realmConfig {
                config.readOnly = readOnly
                if let newRealm = try? Realm(configuration: config) {
                    realmCache[hash] = Weak(value: newRealm)
                    realm = newRealm
                }
            }
        }
        return realm
    }

    func writableDB() -> RealmWrapper? {
        assert(xmppStream != nil)
        if dedicatedRealm != nil {
            return dedicatedRealm

        } else if let config = realmConfig {
            dedicatedRealm = RealmWrapper(configuration: config)
            return dedicatedRealm

        } else {
            return nil
        }
    }

    func addDelegate(delegate:XMPPConnectionDelegate) {
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

    func removeDelegate(delegate:XMPPConnectionDelegate) {
        for var i=0; i < delegates.count; i++ {
            let item = delegates[i]
            if item === delegate {
                delegates.removeAtIndex(i--)
            }
        }
    }

    func invokeDelegates(after: Double = 0, block: (XMPPConnectionDelegate) -> Void) {
        for delegate in delegates {
            Async.main(after: after) {
                block(delegate)
            }
        }
    }

}

// MARK: XMPPStream Delegate
extension XMPPService : XMPPStreamDelegate {
    
    @objc func xmppStream(sender: XMPPStream!, willSecureWithSettings settings: NSMutableDictionary!) {
        let expectedCertName: String? = xmppStream?.myJID.domain

        if expectedCertName != nil {
            settings![kCFStreamSSLPeerName as String] = expectedCertName
        }
        if customCertEvaluation! {
            settings![GCDAsyncSocketManuallyEvaluateTrust] = true
        }
    }

    @objc func xmppStream(sender: XMPPStream!, didReceiveTrust trust: SecTrust!, completionHandler: ((Bool) -> Void)!) {
        var result: SecTrustResultType =  UInt32(kSecTrustResultDeny)
        let success = (SecTrustEvaluate(trust, &result) == noErr)
        
        completionHandler(success)
    }

    @objc func xmppStreamDidConnect(sender: XMPPStream!) {
        #if DEBUG
            print("xmppStreamDidConnected!")
        #endif

        delegates.forEach {
            delegate in delegate.onConnected(self)
        };
    }

    @objc func xmppStreamConnectDidTimeout(sender: XMPPStream!) {
        delegates.forEach {
            delegate in delegate.onDisconnected(self, error: XMPPConnectionError.SocketTimeout)
        }
    }
    
    @objc func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        #if DEBUG
            print("xmppStreamDidAuthenticated!")
        #endif

        delegates.forEach {
            delegate in delegate.onAuthenticated(self)
        }
    }

    @objc func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        #if DEBUG
            print("xmppStreamDidNotAuthenticated!")
        #endif

        delegates.forEach {
            delegate in delegate.onAuthenticationFailed(self)
        }
    }

    @objc func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
        #if DEBUG
            print("xmppStreamDidDisconnect!")
        #endif

        updateBadge()

        if error != nil {
            let notification = NotificationUtils.create(
                title: Localized("Disconnected"),
                body: error.localizedFailureReason ?? Localized("Undefined Error"),
                category: Constants.Notification.Category.Connection)

            notification.fireDate = NSDate().dateByAddingTimeInterval(5)
            NotificationUtils.schedule(notification)
        } 

        delegates.forEach {
            delegate in delegate.onDisconnected(self, error: error)
        }
    }

    @objc func xmppStream(sender: XMPPStream!, didReceiveIQ iq: XMPPIQ!) -> Bool {
        if let session = iq.elementForName("session") {
            #if DEBUG
                print("didReceiveSessionIQ! " + iq.description)
            #endif

            LeagueAssetManager.reloadChampionData()

            let summonerName = session.getElementStringValue("summoner_name", defaultValue: "Unknown")!
            myRosterElement = LeagueRoster(jid: sender.myJID, nickname: summonerName, group: nil)
            if let storedPresence = StoredProperties.Presences.get(sender.myJID.user) {
                myRosterElement!.parsePresence(storedPresence)
            } else {
                myRosterElement!.statusMsg = Constants.XMPP.DefaultStatus
                RiotACS.getSummonerByName(summonerName: summonerName, region: region!) {
                    if let summoner = $0 {
                        self.myRosterElement!.level = summoner.level
                        self.myRosterElement!.profileIcon = summoner.profileIcon
                        self.sendPresence(self.myRosterElement!.getPresenceElement())
                    }
                }
            }
            myRosterElement!.show = .Chat
            myRosterElement!.available = true
            Async.background(after: 0.3, block: {
                let presence = self.myRosterElement!.getPresenceElement()
                self.sendPresence(presence)
            })
        }
        return true
    }

    @objc func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        if presence.isFrom(XMPPJID.jidWithString(sender.myJID.bare(), resource: Constants.XMPP.Resource.PC)) {
            if let currentRoster = myRosterElement {
                let xiffRoster = LeagueRoster(jid: presence.from(), nickname: currentRoster.username, group: nil)
                xiffRoster.parsePresence(presence)
                currentRoster.level = xiffRoster.level
                currentRoster.normalWins = xiffRoster.normalWins
                currentRoster.rankedWins = xiffRoster.rankedWins
                currentRoster.rankedLeagueName = xiffRoster.rankedLeagueName
                currentRoster.rankedLeagueTier = xiffRoster.rankedLeagueTier
                currentRoster.rankedLeagueQueue = xiffRoster.rankedLeagueQueue
                currentRoster.rankedLeagueDivision = xiffRoster.rankedLeagueDivision
                currentRoster.championMasteryScore = xiffRoster.championMasteryScore
                if xiffRoster.status == .HostingGame || xiffRoster.status == .InTeamSelect || xiffRoster.status == .InChampionSelect || xiffRoster.status == .InQueue {
                    currentRoster.priority = -1
                    sendPresence(currentRoster.getPresenceElement())
                } else if currentRoster.priority < 0 {
                    currentRoster.priority = 0
                    sendPresence(currentRoster.getPresenceElement())
                }
            }
        }
    }

    @objc func xmppStream(sender: XMPPStream!, alternativeResourceForConflictingResource conflictingResource: String!) -> String! {
        return conflictingResource + "(\(random()%10))"
    }

    @objc func xmppStream(sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        #if DEBUG
            if error != nil {
                print("xmppStreamDidReceiveError!" + error.description)
                NotificationUtils.schedule(NotificationUtils.create(
                    title: "xmppStreamDidReceiveError",
                    body: error.description,
                    category: Constants.Notification.Category.DebugConnection))
            }
        #endif
    }
}

extension XMPPService : XMPPReconnectDelegate {
    @objc func xmppReconnect(sender: XMPPReconnect!, didDetectAccidentalDisconnect connectionFlags: SCNetworkConnectionFlags) {
        #if DEBUG
            print("didDetectAccidentalDisconnect! \(connectionFlags.description)")

            NotificationUtils.schedule(NotificationUtils.create(
                title: "xmppReconnect",
                body: "Recovered from Accidental Disconnect (code: \(connectionFlags.description))",
                category: Constants.Notification.Category.DebugConnection))
        #endif

        NotificationUtils.dismiss(Constants.Notification.Category.Connection)
        Async.background(after: 1) {
            self.xmppStream?.resendMyPresence()
        }
    }
}

extension XMPPService: XMPPAutoPingDelegate {
    @objc func xmppAutoPingDidTimeout(sender: XMPPAutoPing!) {
        #if DEBUG
            print("xmppAutoPingDidTimeout!")

            NotificationUtils.schedule(NotificationUtils.create(
                title: "xmppAutoPing",
                body: "xmppAutoPingDidTimeout",
                category: Constants.Notification.Category.DebugConnection))

        #endif
    }
}