//
//  NavigationUtils.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 24..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class NavigationUtils {

    static func navigateToReconnect(viewController: UIViewController? = UIApplication.topViewController()) {

        let storyboard = viewController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        if let reconnectViewController = storyboard.instantiateViewControllerWithIdentifier("ReconnectViewController") as? ReconnectViewController {

            reconnectViewController.modalTransitionStyle = .CrossDissolve

            if viewController?.isKindOfClass(ReconnectViewController) == false {
                viewController?.presentViewController(reconnectViewController, animated: true) {
                    UIApplication.sharedApplication().keyWindow?.rootViewController = reconnectViewController
                }
            }
        }
    }

    static func navigateToMain(viewController: UIViewController? = UIApplication.rootViewController()) {

        let storyboard = viewController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = storyboard.instantiateViewControllerWithIdentifier("MainNavController") as? UINavigationController {

            if viewController?.isKindOfClass(ReconnectViewController) == false {
                viewController?.presentViewController(mainViewController, animated: true) {
                    UIApplication.sharedApplication().keyWindow?.rootViewController = mainViewController
                }
            }
        }
    }

    static func navigateToChat(viewController: UIViewController? = UIApplication.topViewController(), chatId: String) {

        let storyboard = viewController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        if let chatViewController = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") as? ChatViewController, chatEntry = XMPPService.sharedInstance.chat()?.getLeagueChatEntry(chatId) {

            if let currentChatViewController = viewController as? ChatViewController {
                if currentChatViewController.chatJID?.user == chatId {
                    return
                }
            }

            chatViewController.setInitialChatData(chatEntry)
            if let sideMenuController = viewController?.sideMenuController() {
                sideMenuController.animateToReveal(false)
            }

            viewController?.navigationController?.pushViewController(chatViewController, animated: true)
        }
    }

    static func navigateToLogin(viewController: UIViewController? = UIApplication.rootViewController()) {
        let storyboard = viewController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as? LoginViewController {

            loginViewController.modalTransitionStyle = .CrossDissolve

            if viewController?.isKindOfClass(LoginViewController) == false {
                viewController?.presentViewController(loginViewController, animated: true) {
                    UIApplication.sharedApplication().keyWindow?.rootViewController = viewController
                }
            }
        }
    }
}

extension UIApplication {

    class func isActive() -> Bool {
        return UIApplication.sharedApplication().applicationState == .Active
    }

    class func rootViewController() -> UIViewController? {
        return UIApplication.sharedApplication().keyWindow?.rootViewController
    }
    
    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {

        if let side = base as? SideMenuController {
            return topViewController(side.centerViewController)
        }
        
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            if let top = moreNavigationController.topViewController where top.view.window != nil {
                return topViewController(top)
            } else if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }

        if let search = base as? UISearchController,
            let parent = search.presentingViewController {
                return parent
        }

        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }

        return base
    }
}
