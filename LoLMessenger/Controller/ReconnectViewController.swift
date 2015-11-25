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
    var isConnecting = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.PrimaryColor
        reconnectingLabel.text = Localized("Connecting...")

        progress.normalBackgroundColor = Theme.HighlightColor
        progress.highlightedBackgroundColor = Theme.HighlightColor.lightenByPercentage(0.1)
        progress.startLoadingAnimation()
    }

    override func viewDidAppear(animated: Bool) {
        // Restore User Credentials if available
        if !isConnecting {
            let keychain = KeychainSwift()
            if let storedUsername = keychain.get(Constants.Key.Username),
                let storedPassword = keychain.get(Constants.Key.Password),
                let storedRegion = LeagueServer.forShorthand(keychain.get(Constants.Key.Region)) {
                    isConnecting = true
                    username = storedUsername
                    password = storedPassword
                    region = storedRegion

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
                isConnecting = false
                self.performSegueWithIdentifier("Login", sender: self)
            }
        }
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
