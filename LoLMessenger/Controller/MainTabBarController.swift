//
//  MainTabBarController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 20..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup

class MainTabBarController : UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        self.delegate = self

        if let roster = XMPPService.sharedInstance.roster() {
            updateRosterBadge(roster)
        }
        if let chat = XMPPService.sharedInstance.chat() {
            updateChatBadge(chat)
        }
    }

    override func viewWillAppear(animated: Bool) {
        // Called when the view is about to made visible.
        XMPPService.sharedInstance.roster()?.addDelegate(self)
        XMPPService.sharedInstance.chat()?.addDelegate(self)

        if let presentedViewController = self.selectedViewController {
            self.tabBarController(self, didSelectViewController: presentedViewController)
        } else {
            self.navigationItem.title = "Friends"
        }
    }

    override func viewDidAppear(animated: Bool) {
        if let presentedViewController = self.selectedViewController {
            self.tabBarController(self, didSelectViewController: presentedViewController)
        }
    }

    override func viewWillLayoutSubviews() {
//        self.tabBar.autoresizingMask = UIViewAutoresizing.None
//        self.view.autoresizingMask = UIViewAutoresizing.FlexibleHeight
//        self.navigationController?.view.autoresizesSubviews = true
//        self.navigationController?.view.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        super.viewWillLayoutSubviews()
    }

    override func viewDidDisappear(animated: Bool) {
        // Called when the view is dismissed, covered or otherwise hidden.
        if let _ = UIApplication.topViewController() as? STPopupContainerViewController {
            XMPPService.sharedInstance.chat()?.removeDelegate(self)
            XMPPService.sharedInstance.roster()?.removeDelegate(self)
        }
    }

    func updateRosterBadge(rosterService: RosterService) {
        if let viewControllers = viewControllers {
            for viewController in viewControllers {
                if viewController.restorationIdentifier == "RosterTableViewController" {
                    let value = rosterService.getNumOfSubscriptionRequests()
                    viewController.tabBarItem?.badgeValue = value > 0 ? String(value) : nil
                    return
                }
            }
        }
    }

    func updateChatBadge(chatService: ChatService) {
        if let viewControllers = viewControllers {
            for viewController in viewControllers {
                if viewController.restorationIdentifier == "RecentChatViewController" {
                    let value = chatService.getNumOfUnreadMessages()
                    viewController.tabBarItem?.badgeValue = value > 0 ? String(value) : nil
                    return
                }
            }
        }
    }

}

extension MainTabBarController : UITabBarControllerDelegate {
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if let navigationItem: UINavigationItem = viewController.navigationItem {
            self.navigationItem.title = navigationItem.title
            self.navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems
            self.navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems
        }
    }
}

extension MainTabBarController : ChatDelegate, RosterDelegate {
    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster) {
        if selectedViewController?.isKindOfClass(RosterTableViewController) == false {
            updateRosterBadge(sender)
        }
    }

    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        if selectedViewController?.isKindOfClass(RecentChatViewController) == false {
            updateChatBadge(sender)
        }
    }
}