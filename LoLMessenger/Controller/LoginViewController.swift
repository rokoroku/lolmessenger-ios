//
//  ViewController.swift
//  LoLMessenger
//
//  Created by 김영록 on 2015. 9. 25..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import KeychainSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var regionButton: UIButton!
    @IBOutlet weak var connectButton: TKTransitionSubmitButton!

    private var isConnecting = false
    private var selectedRegion: LeagueServer?
    private let keychain = KeychainSwift()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.PrimaryColor
        usernameField.backgroundColor = Theme.HighlightColor
        passwordField.backgroundColor = Theme.HighlightColor

        usernameField.placeholder = Localized("Username")
        passwordField.placeholder = Localized("Password")

        connectButton.normalBackgroundColor = Theme.HighlightColor
        connectButton.highlightedBackgroundColor = Theme.HighlightColor.lightenByPercentage(0.1)

        // Looks for single or multiple taps.
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        view.bringSubviewToFront(connectButton)

        // Restore User Credentials if available
        let storedJID = keychain.get(Constants.Key.Username)
        let storedRegion = keychain.get(Constants.Key.Region)

        usernameField.text = storedJID
        selectedRegion = LeagueServer.forShorthand(storedRegion)
        if storedJID != nil {
            let storedPassword = keychain.get(Constants.Key.Password)
            passwordField.text = storedPassword
        }
        regionButton.setTitle(selectedRegion?.name ?? Localized("Select Region"), forState: .Normal)
        accountButton.setTitle(Localized("Need an account?"), forState: .Normal)
        connectButton.setTitle(Localized("Connect"), forState: .Normal)
    }

    override func viewDidAppear(animated: Bool) {
        XMPPService.sharedInstance.addDelegate(self)
        if #available(iOS 9.0, *) {
            UILabel.appearanceWhenContainedInInstancesOfClasses([UILabel.self]).textColor = Theme.TextColorPrimary
        }
    }

    override func viewDidDisappear(animated: Bool) {
        XMPPService.sharedInstance.removeDelegate(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let targetController = segue.destinationViewController as? UINavigationController {
            targetController.transitioningDelegate = self
        }
    }

    @IBAction
    func nextField(sender: AnyObject) {
        if let textField = sender as? UITextField {
            if textField == usernameField {
                passwordField.becomeFirstResponder()
            } else if textField == passwordField {
                dismissKeyboard()
            }
        }
    }

    @IBAction
    func connect(sender: AnyObject) {
        dismissKeyboard()
        if usernameField.text?.isEmpty != true {
            if passwordField.text?.isEmpty != true {
                if let region = selectedRegion {
                    let username = usernameField.text!
                    let password = passwordField.text!
                    if !isConnecting {
                        isConnecting = true
                        connectButton.startLoadingAnimation()
                        Async.background({
                            if !XMPPService.sharedInstance.isXmppConnected {
                                XMPPService.sharedInstance.connect(region)
                            } else if !XMPPService.sharedInstance.isAuthenticated {
                                self.authenticate(username, password: password)
                            } else {
                                Async.main {
                                    self.onAuthenticated(XMPPService.sharedInstance)
                                }
                            }
                        })
                    }
                } else {
                    DialogUtils.alert(Localized("Error"), message: Localized("Please select region"))
                }
            } else {
                DialogUtils.alert(Localized("Error"), message: Localized("Please input password"))
            }
        } else {
            DialogUtils.alert(Localized("Error"), message: Localized("Please input username"))
        }
    }

    func authenticate(username: String, password: String) {
        XMPPService.sharedInstance.login(username, password: password)
    }
    
    func stopConnecting() {
        if isConnecting {
            isConnecting = false
            connectButton.stopLoadingAnimation()
        }
    }

    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @IBAction
    func visitHomepage(sender: AnyObject) {
        if let url = NSURL(string: "http://\(selectedRegion?.shorthand ?? "na").leagueoflegends.com") {
            UIApplication.sharedApplication().openURL(url)
        }
    }

    @IBAction
    func showRegionList(sender: AnyObject) {
        dismissKeyboard()

        let alertController = UIAlertController(title: nil, message: Localized("Select Region"), preferredStyle: .ActionSheet)

        let handler: ((UIAlertAction) -> Void) = { action in
            if let title = action.title {
                self.regionButton.setTitle(title, forState: .Normal)
                self.selectedRegion = LeagueServer.forName(title)!
                if XMPPService.sharedInstance.isXmppConnected {
                    XMPPService.sharedInstance.disconnect()
                }
            }
        }

        for region in LeagueServer.availableRegions {
            let action = UIAlertAction(title: region.name, style: .Default, handler: handler)
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: Localized("Cancel"), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let senderView = sender as? UIView, let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = senderView
            popoverController.sourceRect = senderView.bounds
        }
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}

// MARK: UIViewControllerTransitioningDelegate

extension LoginViewController: UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TKFadeInAnimator(transitionDuration: 0.5, startingAlpha: 0.8)
    }

}

// MARK : XMPPConnectionDelegate

extension LoginViewController : XMPPConnectionDelegate {

    func onConnected(sender: XMPPService) {
        keychain.set(usernameField.text!, forKey: Constants.Key.Username)
        keychain.set(selectedRegion!.shorthand, forKey: Constants.Key.Region)
        authenticate(usernameField.text!, password: passwordField.text!)
    }
    
    func onAuthenticated(sender: XMPPService) {        
        keychain.set(passwordField.text!, forKey: Constants.Key.Password)
        connectButton.startFinishAnimation(0.5,
            completion: {
                self.isConnecting = false
                self.performSegueWithIdentifier("Authenticated", sender: self)
        })
    }
    
    func onDisconnected(sender: XMPPService, error: ErrorType?) {
        if let _ = error {
            DialogUtils.alert(Localized("Error"), message: error.debugDescription)
        }
        stopConnecting()
    }
    
    func onAuthenticationFailed(sender: XMPPService) {
        DialogUtils.alert(Localized("Error"),
            message: Localized("Authentication Failed, Check your credential and region"))
        stopConnecting()
    }

}
