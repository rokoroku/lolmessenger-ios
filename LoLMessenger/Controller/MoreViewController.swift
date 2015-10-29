//
//  MoreViewController.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 25..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Eureka
import ChameleonFramework

class MoreViewController : FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ accountSection()
        form +++ notificationSection()
        form +++ friendSection()
        form +++ chatSection()
        navigationController?.hidesNavigationBarHairline = true
    }

    func accountSection() -> Section {
        return Section("Account")
            <<< FloatLabelRow() {
                $0.title = "Username"
                $0.value = NSUserDefaults.standardUserDefaults().stringForKey(Constants.Key.Username)
                $0.disabled = true
            }
            <<< FloatLabelRow() {
                $0.title =  "Summoner Name"
                $0.value = XMPPService.sharedInstance.myRosterElement?.username ?? "Unknown"
                $0.disabled = true
            }
            <<< FloatLabelRow() {
                $0.title =  "Status Message"
                $0.value = XMPPService.sharedInstance.myRosterElement?.statusMsg
                $0.onChange {
                    if let myRoster = XMPPService.sharedInstance.myRosterElement {
                        myRoster.statusMsg = $0.value
                        XMPPService.sharedInstance.sendPresence(myRoster.getPresenceElement())
                    }
                }
            }
    }

    func notificationSection() -> Section {
        return Section("Notification")
            <<< SwitchRow() {
                $0.title = "Friend Subscription"
                $0.value = StoredProperties.Settings.notifySubscription.value
                $0.onChange { StoredProperties.Settings.notifySubscription.value = $0.value! as Bool }
            }
            <<< SwitchRow() {
                $0.title = "New Message"
                $0.value = StoredProperties.Settings.notifyMessage.value
                $0.onChange { StoredProperties.Settings.notifyMessage.value = $0.value! as Bool }
            }
            <<< MultipleSelectorRow<String>() {
                $0.title = "Alert Type"
                $0.options = ["Sound", "Vibrate"]
                var selectedOptions = Set<String>()
                if StoredProperties.Settings.notifyWithSound.value { selectedOptions.insert("Sound") }
                if StoredProperties.Settings.notifyWithVibrate.value { selectedOptions.insert("Vibrate") }
                $0.value = selectedOptions
                $0.onChange {
                    StoredProperties.Settings.notifyWithSound.value = $0.value?.contains("Sound") ?? false
                    StoredProperties.Settings.notifyWithVibrate.value = $0.value?.contains("Vibrate") ?? false
                }
            }.onPresent { from, to in
                to.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: from, action: "multipleSelectorDone:")
            }
    }

    func friendSection() -> Section {
        return Section("Friend List")
            <<< SwitchRow() {
                $0.title = "Show Offline Group"
                $0.value = true
            }
            <<< SwitchRow() {
                $0.title = "Sort by"
                $0.value = true
            }
    }


    func chatSection() -> Section {
        return Section("Chat")
            <<< SwitchRow() {
                $0.title = "Enter to Send"
                $0.value = true
            }
            <<< SwitchRow() {
                $0.title = "Show unread message first"
                $0.value = true
            }
    }

    override func viewWillLayoutSubviews() {
        let adjustForTabbarInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.tableView!.contentInset = adjustForTabbarInsets
        self.tableView!.scrollIndicatorInsets = adjustForTabbarInsets
    }

    override func viewDidAppear(animated: Bool) {
        self.tableView!.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: .Top)
    }

    func multipleSelectorDone(item:UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
}