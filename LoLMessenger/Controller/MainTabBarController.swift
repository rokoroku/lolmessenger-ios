//
//  MainTabBarController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 20..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class MainTabBarController : UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        self.delegate = self
        self.view.autoresizingMask = UIViewAutoresizing.FlexibleHeight

        updateRosterBadge(XMPPService.sharedInstance.roster())
        updateChatBadge(XMPPService.sharedInstance.chat())
    }

    override func viewWillAppear(animated: Bool) {
        // Called when the view is about to made visible.
        XMPPService.sharedInstance.roster().addDelegate(self)
        XMPPService.sharedInstance.chat().addDelegate(self)
    }

    override func viewWillDisappear(animated: Bool) {
        // Called when the view is dismissed, covered or otherwise hidden.
        XMPPService.sharedInstance.roster().removeDelegate(self)
        XMPPService.sharedInstance.chat().addDelegate(self)
    }

    func updateRosterBadge(rosterService: RosterService) {
        for viewController in viewControllers! {
            if viewController.restorationIdentifier == "RosterTableViewController" {
                let value = rosterService.getNumOfSubscriptionRequests()
                viewController.tabBarItem?.badgeValue = value > 0 ? String(value) : nil
                return
            }
        }
    }

    func updateChatBadge(chatService: ChatService) {
        for viewController in viewControllers! {
            if viewController.restorationIdentifier == "RecentChatViewController" {
                let value = chatService.getNumOfUnreadMessages()
                viewController.tabBarItem?.badgeValue = value > 0 ? String(value) : nil
                return
            }
        }
    }

}

extension MainTabBarController : UITabBarControllerDelegate {
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
//        if let tabBarItem = viewController.tabBarItem {
//            tabBarItem.badgeValue = nil
//        }
    }
}

extension MainTabBarController : ChatDelegate, RosterDelegate {
    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster) {
        updateRosterBadge(sender)
    }

    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        updateChatBadge(sender)
    }
}