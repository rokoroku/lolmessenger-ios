//
//  MainViewController.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 26..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class MainViewController : SideMenuController {
    override func viewDidLoad() {
        let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = storyboard.instantiateViewControllerWithIdentifier("MainNavController") as? UINavigationController {
            self.centerViewController = mainViewController
        }
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().keyWindow?.rootViewController = self
        UIApplication.sharedApplication().keyWindow?.makeKeyAndVisible()
        super.viewWillAppear(animated)
    }
}