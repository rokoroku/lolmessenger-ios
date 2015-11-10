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

    lazy var logoutButton: UIButton = {
        let button = UIButton(type: UIButtonType.System)
        button.setTitle("Sign out", forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: "confirmLogout", forControlEvents: .TouchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.backgroundColor = Theme.PrimaryColor

        form +++ accountSection()
        form +++ backgroundSection()
        form +++ notificationSection()

//        form +++ friendSection()
//        form +++ chatSection()

        navigationController?.hidesNavigationBarHairline = true
    }

    func confirmLogout() {
        DialogUtils.alert("Sign out", message: "Are you sure you want to sign out?", handler: { _ in
            XMPPService.sharedInstance.disconnect()
            NavigationUtils.navigateToLogin()
        })

    }

    func accountSection() -> Section {

        return Section("Account")
            <<< FloatLabelRow() {
                $0.title =  "Summoner Name"
                $0.value = XMPPService.sharedInstance.myRosterElement?.username ?? "Unknown"
                $0.disabled = true
                $0.cell.accessoryView = self.logoutButton
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
            
//            <<< LabelRow () {
//                $0.title = "Display Status"
//                $0.value = "Online"
//                $0.onCellSelection {
//                    if let detailTextLabel = $0.cell.detailTextLabel {
//                        if detailTextLabel.text == "Online" {
//                            detailTextLabel.text = "Away"
//                            detailTextLabel.textColor = Theme.RedColor
//                        } else {
//                            detailTextLabel.text = "Online"
//                            detailTextLabel.textColor = Theme.GreenColor
//                        }
//                    }
//                }
//            }
    }

    func notificationSection() -> Section {
        return Section("Notification")
            <<< SwitchRow() {
                $0.title = "New Message"
                $0.value = StoredProperties.Settings.notifyMessage.value
                $0.onChange { StoredProperties.Settings.notifyMessage.value = $0.value! as Bool }
            }
            <<< SwitchRow() {
                $0.title = "New Friend Request"
                $0.value = StoredProperties.Settings.notifySubscription.value
                $0.onChange { StoredProperties.Settings.notifySubscription.value = $0.value! as Bool }
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

    func backgroundSection() -> Section {
        return Section(header: "Background Session", footer: "Since the time of background task is limited to about 3 minutes by Apple, the connection will be closed until reopen the application.")
            <<< SwitchRow() {
                $0.title = "Expiration Warning"
                $0.value = StoredProperties.Settings.notifySubscription.value
                $0.onChange { StoredProperties.Settings.notifySubscription.value = $0.value! as Bool }
        }
    }


    func friendSection() -> Section {
        return Section("Friend List")
            <<< SwitchRow() {
                $0.title = "Separate Offline Group"
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
        self.tableView?.contentInset = adjustForTabbarInsets
        self.tableView?.scrollIndicatorInsets = adjustForTabbarInsets
    }

    override func viewDidAppear(animated: Bool) {
        self.tableView?.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: .Top)
    }

    func multipleSelectorDone(item:UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
}

//extension MoreViewController {
//    func tableView(tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
//        if let headerView = view as? UITableViewHeaderFooterView {
//            if headerView.textLabel?.text == "ACCOUNT" {
//                if !headerView.subviews.contains(logoutButton) {
//                    headerView.addSubview(logoutButton)
//                }
//                logoutButton.frame.origin.y = headerView.textLabel!.frame.origin.y - (logoutButton.frame.height - headerView.textLabel!.frame.height)/2
//                logoutButton.frame.origin.x = headerView.frame.width - (headerView.textLabel?.frame.origin.x)! - logoutButton.frame.width
//                headerView.layoutSubviews()
//                
//            } else if headerView.subviews.contains(logoutButton) {
//                logoutButton.removeFromSuperview()
//            }
//        }
//    }
//}