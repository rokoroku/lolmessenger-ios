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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var backgroundTimer: NSTimer?
    var didShowDisconnectionWarning = false
    var shouldRedirectToReconnect = false

    // MARK: UIApplicationDelegate    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        Fabric.with([Crashlytics.self])

        application.statusBarStyle = .LightContent
        Theme.applyGlobalTheme()

        let settings = UIUserNotificationSettings(
            forTypes: [.Alert, .Badge, .Sound],
            categories: nil)
        application.registerUserNotificationSettings(settings)

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        print("Application entered background state")

        //todo: application badge update
        didShowDisconnectionWarning = false
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        backgroundTask = application.beginBackgroundTaskWithExpirationHandler {
            Async.main {
                print("Background Task Expired")
                application.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
        backgroundTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "timerUpdate:", userInfo: nil, repeats: true)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let mainTabBarController = UIApplication.topViewController()?.tabBarController as? MainTabBarController {
            if XMPPService.sharedInstance.isAuthenticated {
                mainTabBarController.updateRosterBadge(XMPPService.sharedInstance.roster())
                mainTabBarController.updateChatBadge(XMPPService.sharedInstance.chat())
            }
        }

        self.backgroundTimer?.invalidate()
        self.backgroundTimer = nil
        if (self.backgroundTask != UIBackgroundTaskInvalid) {
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }

        NotificationUtils.dismiss(Constants.Notification.Category.Connection)

        didShowDisconnectionWarning = false

        if shouldRedirectToReconnect {
            shouldRedirectToReconnect = false
            NavigationUtils.navigateToReconnect()
        }
    }


    func timerUpdate(timer: NSTimer) {

        let application = UIApplication.sharedApplication()

        #if DEBUG
            print("timer update, background time left: %f", application.backgroundTimeRemaining)
        #endif

        if application.backgroundTimeRemaining < 60 && !didShowDisconnectionWarning {

            NotificationUtils.dismiss(Constants.Notification.Category.Connection)
            NotificationUtils.schedule(NotificationUtils.create(
                title: "Warning",
                body: "Background session will be expired in one minute.",
                action: "Open",
                category: Constants.Notification.Category.Connection))

            didShowDisconnectionWarning = true
        }

        if application.backgroundTimeRemaining <= 10 && !shouldRedirectToReconnect {
            // Clean up here
            self.backgroundTimer?.invalidate()
            self.backgroundTimer = nil

            NotificationUtils.dismiss(Constants.Notification.Category.Connection)
            NotificationUtils.schedule(NotificationUtils.create(
                title: "Disconnected",
                body: "Your presence has gone offline.",
                action: "Reconnect",
                category: Constants.Notification.Category.Connection))

            XMPPService.sharedInstance.disconnect()
            shouldRedirectToReconnect = true

            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    func applicationWillTerminate(application: UIApplication) {
//        if UIApplication.topViewController()?.isKindOfClass(LoginViewController) == false {
//            NotificationUtils.dismiss(Constants.Notification.Category.Connection)
//            NotificationUtils.schedule(NotificationUtils.create(
//                title: "Disconnected",
//                body: "Application has been terminated.",
//                category: Constants.Notification.Category.Connection))
//        }
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let chatId = notification.userInfo?[Constants.Notification.UserInfo.ChatID] as? String,
            let wasActive = notification.userInfo?[Constants.Notification.UserInfo.AppState] as? Bool {
                if wasActive {
                    if let roster = XMPPService.sharedInstance.roster().getRosterByJID(chatId) {
                        let banner = Banner(
                            title: roster.username,
                            subtitle: try! notification.alertBody!.split(" : ")[1],
                            image: roster.getProfileIcon(),
                            backgroundColor: Theme.SecondaryColor,
                            didTapBlock: { NavigationUtils.navigateToChat(chatId: chatId) }
                        )
                        NotificationUtils.alert()
                        banner.show(duration: 3.0)
                    }
                } else {
                    NavigationUtils.navigateToChat(chatId: chatId)
                }
        }
    }

}

