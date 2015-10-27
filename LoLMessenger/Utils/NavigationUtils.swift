//
//  NavigationUtils.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 24..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

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
