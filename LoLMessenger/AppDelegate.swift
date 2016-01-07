//
//  AppDelegate.swift
//  LoLMessenger
//
//  Created by 김영록 on 2015. 9. 25..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import RealmSwift

protocol BackgroundDelegate : class {
    func didEnterBackground(sender: UIApplication)
    func didBecomeActive(sender: UIApplication)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var backgroundTimer: NSTimer?
    var didShowDisconnectionWarning = false
    var shouldRedirectToReconnect = false

    private static var delegates: [BackgroundDelegate] = []

    // MARK: UIApplicationDelegate
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {

        // initiate Fabric
        Fabric.with([Crashlytics.self])

        // apply theme
        application.statusBarStyle = .LightContent
        Theme.applyGlobalTheme()

        // add localNotification setting
        let settings = UIUserNotificationSettings(
            forTypes: [.Alert, .Badge, .Sound],
            categories: nil)
        application.registerUserNotificationSettings(settings)

        // add uncaughtExceptionHandler
        NSSetUncaughtExceptionHandler { exception in
            print(exception)

            if XMPPService.sharedInstance.isAuthenticated == true {
                XMPPService.sharedInstance.disconnect()

                let notification = NotificationUtils.create(
                    title: Localized("Disconnected"),
                    body: exception.reason != nil ? "Error: \(exception.reason!)" : Localized("Undefined Error"),
                    action: Localized("Reconnect"),
                    category: Constants.Notification.Category.Connection)

                NotificationUtils.dismiss(Constants.Notification.Category.Connection)
                NotificationUtils.schedule(notification)
            }
        }

        // add admixer settings
        AdMixer.registerUserAdAdapterName("iad", cls: IAdAdapter.self)
        AdMixer.registerUserAdAdapterNameWithAppCode("cauly", cls: CaulyAdapter.self, appCode: "UOtNQb0T")
        AdMixer.registerUserAdAdapterNameWithAppCode("admob", cls: AdmobAdapter.self, appCode: "ca-app-pub-6442282031136715/5528204184")
        AdMixer.registerUserAdAdapterNameWithAppCode("facebook", cls: FacebookAdapter.self, appCode: "1458789581093742_1495589060747127")

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        #if DEBUG
            print("Application entered background state")
        #endif

        //todo: application badge update
        didShowDisconnectionWarning = false

        if !StoredProperties.Settings.backgroundEnabled && XMPPService.sharedInstance.isAuthenticated {
            backgroundTask = application.beginBackgroundTaskWithExpirationHandler {
                Async.main {
                    application.endBackgroundTask(self.backgroundTask)
                    self.backgroundTask = UIBackgroundTaskInvalid
                }
            }
            backgroundTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "timerUpdate:", userInfo: nil, repeats: true)
        }

        AppDelegate.delegates.forEach { $0.didEnterBackground(application) }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        #if DEBUG
            print("Application did become active")
        #endif

        self.backgroundTimer?.invalidate()
        self.backgroundTimer = nil
        if (self.backgroundTask != UIBackgroundTaskInvalid) {
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }

        NotificationUtils.dismiss(Constants.Notification.Category.Connection)
        didShowDisconnectionWarning = false

        if shouldRedirectToReconnect && !XMPPService.sharedInstance.isAuthenticated {
            NavigationUtils.navigateToReconnect()
            shouldRedirectToReconnect = false
        } else {
            AppDelegate.delegates.forEach { $0.didBecomeActive(application) }
        }
    }


    func timerUpdate(timer: NSTimer) {

        let application = UIApplication.sharedApplication()

        #if DEBUG
            print("timer update, background time left: \(application.backgroundTimeRemaining)")
        #endif
 
        let isConnected = XMPPService.sharedInstance.isAuthenticated
        if application.backgroundTimeRemaining < 45 && !didShowDisconnectionWarning && isConnected {
            if StoredProperties.Settings.notifyBackgroundExpire.value {

                let notification = NotificationUtils.create(
                    title: Localized("Warning"),
                    body: Localized("Background session will be expired in one minute."),
                    action: Localized("Open"),
                    category: Constants.Notification.Category.Connection)

                let playSound = StoredProperties.Settings.backgroundNotifyWithSound.value
                notification.soundName = playSound ? UILocalNotificationDefaultSoundName : nil

                NotificationUtils.dismiss(Constants.Notification.Category.Connection)
                NotificationUtils.schedule(notification)
            }

            didShowDisconnectionWarning = true
        }
        else if (application.backgroundTimeRemaining <= 5 && !shouldRedirectToReconnect) || !isConnected {
            // Clean up here
            self.backgroundTimer?.invalidate()
            self.backgroundTimer = nil

            let notification = NotificationUtils.create(
                title: Localized("Disconnected"),
                body: Localized("Your presence has gone offline."),
                action: Localized("Reconnect"),
                category: Constants.Notification.Category.Connection)

            let playSound = StoredProperties.Settings.backgroundNotifyWithSound.value
            notification.soundName = playSound ? UILocalNotificationDefaultSoundName : nil

            NotificationUtils.dismiss(Constants.Notification.Category.Connection)
            NotificationUtils.schedule(notification)

            XMPPService.sharedInstance.disconnect()
            shouldRedirectToReconnect = true

            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    func applicationWillTerminate(application: UIApplication) {

    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let chatId = notification.userInfo?[Constants.Notification.UserInfo.ChatID] as? String,
            let wasActive = notification.userInfo?[Constants.Notification.UserInfo.AppState] as? Bool {
                if wasActive {
                    if let roster = XMPPService.sharedInstance.roster()?.getRosterByJID(chatId) {
                        LeagueAssetManager.getProfileIcon(roster.profileIcon ?? -1) {
                            let image = $0 ?? UIImage(named: "profile_unknown")
                            let banner = Banner(
                                title: roster.username,
                                subtitle: try? notification.alertBody!.split(" : ")[1],
                                image: image,
                                backgroundColor: Theme.SecondaryColor,
                                didTapBlock: { NavigationUtils.navigateToChat(chatId: chatId) }
                            )
                            NotificationUtils.alert()
                            banner.show(duration: 3.0)
                        }
                    }
                } else if XMPPService.sharedInstance.isAuthenticated {
                    NavigationUtils.navigateToChat(chatId: chatId)
                }
        }
    }


    class func addDelegate(delegate: BackgroundDelegate) {
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

    class func removeDelegate(delegate: BackgroundDelegate) {
        for var i=0; i < delegates.count; i++ {
            let item = delegates[i]
            if item === delegate {
                delegates.removeAtIndex(i--)
            }
        }
    }

}

