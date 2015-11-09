//
//  NavigationUtils.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 24..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class NavigationUtils {
    class func navigateToChat(viewController: UIViewController? = UIApplication.topViewController(), chatId: String) {
        if let rootViewController = viewController,
            let chatViewController = rootViewController.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as? ChatViewController,
            let chatEntry = XMPPService.sharedInstance.chat().getLeagueChatEntry(chatId) {

                if let rootChatViewController = rootViewController as? ChatViewController {
                    if rootChatViewController.chatJID?.user == chatId {
                        return
                    }
                }

                chatViewController.setInitialChatData(chatEntry)
                if let navigationController = rootViewController.navigationController {
                    navigationController.pushViewController(chatViewController, animated: true)
                } else {
                    rootViewController.presentViewController(chatViewController, animated: true, completion: nil)
                }
        }
    }

    class func navigateToLogin(viewController: UIViewController? = UIApplication.rootViewController()) {
        let storyboard = viewController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        if let loginController = storyboard.instantiateInitialViewController() {
            loginController.modalTransitionStyle = .CrossDissolve
            viewController?.presentViewController(loginController, animated: true) {
                UIApplication.sharedApplication().keyWindow?.rootViewController = loginController
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
