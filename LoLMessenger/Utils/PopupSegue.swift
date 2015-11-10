//
//  PopupSegue.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 10..
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
                popupController.presentInViewController(UIApplication.topViewController())
            }
        }
    }
}
