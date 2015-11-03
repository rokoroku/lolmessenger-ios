//
//  NavigationUtils.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 24..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup

class PopupSegue : UIStoryboardSegue {

    var shouldPerform:Bool = true

    override func perform() {
        if shouldPerform {
            let screenSize = UIScreen.mainScreen().bounds.size
            var contentSize = CGSizeMake(screenSize.width - 32, screenSize.height/2)
            if contentSize.width > 340 { contentSize.width = 340 }

            self.destinationViewController.contentSizeInPopup = contentSize
            self.destinationViewController.landscapeContentSizeInPopup = contentSize

            let popupController = STPopupController(rootViewController: self.destinationViewController)
            popupController.navigationBarHidden = true
            popupController.transitionStyle = .Fade
            popupController.cornerRadius = 16

            Async.main {
                popupController.presentInViewController(self.sourceViewController)
            }
        }
    }
}

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
}

extension UIApplication {

    class func isActive() -> Bool {
        return UIApplication.sharedApplication().applicationState == .Active
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

        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        
        return base
    }
}
