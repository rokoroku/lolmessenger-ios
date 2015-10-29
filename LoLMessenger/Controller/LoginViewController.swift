//
//  ViewController.swift
//  LoLMessenger
//
//  Created by 김영록 on 2015. 9. 25..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import TKSubmitTransition

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var connectButton: TKTransitionSubmitButton!
    
    private var isConnecting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.PrimaryColor
        usernameField.backgroundColor = Theme.HighlightColor.darkenByPercentage(0.02)
        passwordField.backgroundColor = Theme.HighlightColor.darkenByPercentage(0.02)
        connectButton.normalBackgroundColor = Theme.HighlightColor
        connectButton.highlightedBackgroundColor = Theme.HighlightColor.lightenByPercentage(0.1)

        // Looks for single or multiple taps.
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        view.bringSubviewToFront(connectButton)

        // Restore User Credentials if available
        let myJID = NSUserDefaults.standardUserDefaults().stringForKey(Constants.Key.Username)
        let myPassword = NSUserDefaults.standardUserDefaults().stringForKey(Constants.Key.Password)

        usernameField.text = myJID
        passwordField.text = myPassword

        if XMPPService.sharedInstance.isAuthenticated {
            let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("TabController") as UIViewController!
            viewController.transitioningDelegate = self
            self.presentViewController(viewController, animated: true, completion: nil)
        }
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
                    XMPPService.sharedInstance.connect(LeagueServer.KR)
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

    func dismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
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
        NSUserDefaults.standardUserDefaults().setValue(usernameField.text, forKeyPath: Constants.Key.Username)
        authenticate()
    }
    
    func onAuthenticated(sender: XMPPService) {        
        NSUserDefaults.standardUserDefaults().setValue(passwordField.text, forKeyPath: Constants.Key.Password)
        connectButton.startFinishAnimation(0.5,
            completion: {
                let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("TabBarController") as UIViewController!
                viewController.transitioningDelegate = self
                self.presentViewController(viewController, animated: true, completion: nil)
        })
    }
    
    func onDisconnected(sender: XMPPService, error: ErrorType?) {
        let alert = UIAlertController(title: "Error", message: error.debugDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(alert, animated: true, completion: nil)

        stopConnecting()
    }
    
    func onAuthenticationFailed(sender: XMPPService) {
        let alert = UIAlertController(title: "Error", message: "Authentication Failed", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        
        stopConnecting()
    }

}
