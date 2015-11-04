//
//  ViewController.swift
//  LoLMessenger
//
//  Created by 김영록 on 2015. 9. 25..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import TKSubmitTransition
import KeychainSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var regionButton: UIButton!
    @IBOutlet weak var connectButton: TKTransitionSubmitButton!

    private var isConnecting = false
    private var selectedRegion: LeagueServer = LeagueServer.KR
    private let keychain = KeychainSwift()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.PrimaryColor
        usernameField.backgroundColor = Theme.HighlightColor
        passwordField.backgroundColor = Theme.HighlightColor
        //regionButton.backgroundColor = Theme.HighlightColor
        //regionButton.layer.cornerRadius = 4

        connectButton.normalBackgroundColor = Theme.HighlightColor
        connectButton.highlightedBackgroundColor = Theme.HighlightColor.lightenByPercentage(0.1)

        // Looks for single or multiple taps.
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        view.bringSubviewToFront(connectButton)

        // Restore User Credentials if available
        let myJID = keychain.get(Constants.Key.Username)
        let myPassword = keychain.get(Constants.Key.Password)
        let myRegion = keychain.get(Constants.Key.Region)

        usernameField.text = myJID
        passwordField.text = myPassword
        selectedRegion = LeagueServer.forShorthand(myRegion ?? "KR")!
        regionButton.setTitle(selectedRegion.name, forState: .Normal)

        if XMPPService.sharedInstance.isAuthenticated {
            let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("TabController") as UIViewController!
            viewController.transitioningDelegate = self
            self.presentViewController(viewController, animated: true, completion: nil)
        }
    }

    @IBAction
    func nextField(sender: AnyObject) {
        passwordField.becomeFirstResponder()
    }

    @IBAction
    func connect(sender: AnyObject) {
        dismissKeyboard()
        if !isConnecting {
            isConnecting = true
            connectButton.startLoadingAnimation()
            Async.background({
                if !XMPPService.sharedInstance.isXmppConnected {
                    XMPPService.sharedInstance.addDelegate(self)
                    XMPPService.sharedInstance.connect(self.selectedRegion)
                } else {
                    self.authenticate()
                }
            })
        }
    }

    func authenticate() {
        let username = usernameField.text!
        let password = passwordField.text!
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
        if let url = NSURL(string: "http://\(selectedRegion.shorthand).leagueoflegends.com") {
            UIApplication.sharedApplication().openURL(url)
        }
    }

    @IBAction
    func showRegionList(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: "Choose Region", preferredStyle: .ActionSheet)
        let handler: ((UIAlertAction) -> Void) = { action in
            self.regionButton.setTitle(action.title, forState: .Normal)
            self.selectedRegion = LeagueServer.forName(action.title!)!
            if XMPPService.sharedInstance.isXmppConnected {
                XMPPService.sharedInstance.disconnect()
            }
        }

        for region in LeagueServer.availableRegions {
            let action = UIAlertAction(title: region.name, style: .Default, handler: handler)
            optionMenu.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        optionMenu.addAction(cancelAction)
        
        dismissKeyboard()
        presentViewController(optionMenu, animated: true, completion: nil)
    }
}

// MARK: UIViewControllerTransitioningDelegate

extension LoginViewController: UIViewControllerTransitioningDelegate {

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TKFadeInAnimator(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

}

// MARK : XMPPConnectionDelegate

extension LoginViewController : XMPPConnectionDelegate {

    func onConnected(sender: XMPPService) {
        keychain.set(usernameField.text!, forKey: Constants.Key.Username)
        keychain.set(selectedRegion.shorthand, forKey: Constants.Key.Region)
        authenticate()
    }
    
    func onAuthenticated(sender: XMPPService) {        
        keychain.set(passwordField.text!, forKey: Constants.Key.Password)
        connectButton.startFinishAnimation(0.5,
            completion: {
                let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("TabBarController") as UIViewController!
                viewController.transitioningDelegate = self
                self.presentViewController(viewController, animated: true, completion: nil)
        })
    }
    
    func onDisconnected(sender: XMPPService, error: ErrorType?) {
        if let _ = error {
            let alert = UIAlertController(title: "Error", message: error.debugDescription, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
            UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        }
        stopConnecting()
    }
    
    func onAuthenticationFailed(sender: XMPPService) {
        let alert = UIAlertController(title: "Error", message: "Authentication Failed", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        
        stopConnecting()
    }

}
