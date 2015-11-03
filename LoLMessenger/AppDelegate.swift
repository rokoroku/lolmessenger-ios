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
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var audioPlayer: AVAudioPlayer?

    // MARK: UIApplicationDelegate    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        // Override point for customization after application launch.

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
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

    func application(application: UIApplication, didChangeStatusBarFrame oldStatusBarFrame: CGRect) {

    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let chatId = notification.userInfo?[Constants.Notification.ChatID] as? String,
            let wasActive = notification.userInfo?[Constants.Notification.AppState] as? Bool {
                if wasActive {
                    if let roster = XMPPService.sharedInstance.roster().getRosterByJID(chatId) {
                        let banner = Banner(
                            title: roster.username,
                            subtitle: try! notification.alertBody!.split(" : ")[1],
                            image: roster.getProfileIcon(),
                            backgroundColor: Theme.SecondaryColor,
                            didTapBlock: { NavigationUtils.navigateToChat(chatId: chatId) }
                        )
                        alert()
                        banner.show(duration: 3.0)
                    }
                } else {
                    NavigationUtils.navigateToChat(chatId: chatId)
                }
        }
    }

    func alert(vibrate: Bool = StoredProperties.Settings.notifyWithVibrate.value, sound: Bool = StoredProperties.Settings.notifyWithSound.value) {
        if vibrate {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        if sound {
            AudioServicesPlaySystemSound(1002)
        }
    }
}

