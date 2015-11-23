//
//  ReconnectViewController.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 10..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import KeychainSwift

class ReconnectViewController : UIViewController {

    @IBOutlet weak var progress: TKTransitionSubmitButton!
    @IBOutlet weak var reconnectingLabel: UILabel!

    var username: String?
    var password: String?
    var region: LeagueServer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.PrimaryColor
        reconnectingLabel.text = Localized("Connecting...")

        progress.normalBackgroundColor = Theme.HighlightColor
        progress.highlightedBackgroundColor = Theme.HighlightColor.lightenByPercentage(0.1)
    }

    override func viewWillAppear(animated: Bool) {
        // Restore User Credentials if available
        let keychain = KeychainSwift()
        if let storedUsername = keychain.get(Constants.Key.Username),
            let storedPassword = keychain.get(Constants.Key.Password),
            let storedRegion = LeagueServer.forShorthand(keychain.get(Constants.Key.Region)) {
                username = storedUsername
                password = storedPassword
                region = storedRegion

                progress.startLoadingAnimation()
                Async.background({
                    XMPPService.sharedInstance.addDelegate(self)
                    if !XMPPService.sharedInstance.isXmppConnected {
                        XMPPService.sharedInstance.connect(storedRegion)
                    } else if !XMPPService.sharedInstance.isAuthenticated {
                        XMPPService.sharedInstance.login(storedUsername, password: storedPassword)
                    } else {
                        Async.main {
                            self.onAuthenticated(XMPPService.sharedInstance)
                        }
                    }
                })
        } else {
            performSegueWithIdentifier("Login", sender: self)
        }
    }
}

extension ReconnectViewController: UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TKFadeInAnimator(transitionDuration: 0.5, startingAlpha: 0.8)
    }

}

// MARK : XMPPConnectionDelegate

extension ReconnectViewController: XMPPConnectionDelegate {

    func onConnected(sender: XMPPService) {
        XMPPService.sharedInstance.login(username!, password: password!)
    }

    func onAuthenticated(sender: XMPPService) {
        progress.startFinishAnimation(0.5) {
            self.performSegueWithIdentifier("Enter", sender: self)
        }
    }

    func onDisconnected(sender: XMPPService, error: ErrorType?) {
        performSegueWithIdentifier("Login", sender: self)
    }

    func onAuthenticationFailed(sender: XMPPService) {
        performSegueWithIdentifier("Login", sender: self)
    }
}
