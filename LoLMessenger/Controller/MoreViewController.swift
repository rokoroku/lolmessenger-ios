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
        button.setTitle(Localized("Sign out"), forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: "confirmLogout", forControlEvents: .TouchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.backgroundColor = Theme.PrimaryColor

        updateLocale()

        form +++ accountSection()
        form +++ notificationSection()
        if !StoredProperties.Settings.backgroundEnabled { form +++ backgroundSection() }
        //form +++ friendSection()
        //form +++ chatSection()
        form +++ othersSection()
        

        navigationController?.hidesNavigationBarHairline = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateLocale", name: LCLLanguageChangeNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        navigationController?.delegate = self
    }

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LCLLanguageChangeNotification, object: nil)
    }

    func updateLocale() {
        navigationItem.title = Localized("Setting")
        if tabBarItem != nil { tabBarItem.title = Localized("Setting") }
    }

    func confirmLogout() {
        DialogUtils.alert(Localized("Sign out"),
            message: Localized("Are you sure you want to sign out?"),
            handler: { _ in
                XMPPService.sharedInstance.disconnect()
                NavigationUtils.navigateToLogin()
        })
    }

    func accountSection() -> Section {
        return Section(Localized("Account"))
            <<< FloatLabelRow() {
                $0.title =  Localized("Summoner Name")
                $0.value = XMPPService.sharedInstance.myRosterElement?.username ?? Constants.XMPP.Unknown
                $0.disabled = true
                $0.cell.accessoryView = self.logoutButton
            }

            <<< FloatLabelRow() {
                $0.title =  Localized("Status Message")
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
        return Section(Localized("Notification"))
            <<< SwitchRow() {
                $0.title = Localized("New Message")
                $0.value = StoredProperties.Settings.notifyMessage.value
                $0.onChange { StoredProperties.Settings.notifyMessage.value = $0.value! as Bool }
            }
            <<< SwitchRow() {
                $0.title = Localized("New Friend Request")
                $0.value = StoredProperties.Settings.notifySubscription.value
                $0.onChange { StoredProperties.Settings.notifySubscription.value = $0.value! as Bool }
            }
            <<< MultipleSelectorRow<String>() {
                $0.title = Localized("Alert Type")
                $0.options = [Localized("Sound"), Localized("Vibrate")]
                var selectedOptions = Set<String>()
                if StoredProperties.Settings.notifyWithSound.value { selectedOptions.insert(Localized("Sound")) }
                if StoredProperties.Settings.notifyWithVibrate.value { selectedOptions.insert(Localized("Vibrate")) }
                $0.value = selectedOptions
                $0.onChange {
                    StoredProperties.Settings.notifyWithSound.value = $0.value?.contains(Localized("Sound")) ?? false
                    StoredProperties.Settings.notifyWithVibrate.value = $0.value?.contains(Localized("Vibrate")) ?? false
                }
            }.onPresent { from, to in
                to.navigationItem.title = Localized("Alert Type")
                to.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: from, action: "multipleSelectorDone:")
            }
    }

    func backgroundSection() -> Section {
        return Section(
            header: Localized("Background Session"),
            footer: Localized("Since the time of background task is limited to about 3 minutes by Apple's app policy, application will be terminated after the given amount of time."))
            <<< SwitchRow() {
                $0.title = Localized("Expiration Warning")
                $0.value = StoredProperties.Settings.notifyBackgroundExpire.value
                $0.onChange { StoredProperties.Settings.notifyBackgroundExpire.value = $0.value! as Bool }
            }
            <<< SwitchRow() {
                $0.title = Localized("Play notification sound")
                $0.value = StoredProperties.Settings.backgroundNotifyWithSound.value
                $0.onChange { StoredProperties.Settings.backgroundNotifyWithSound.value = $0.value! as Bool }
        }
    }


    func friendSection() -> Section {
        return Section(Localized("Friend List"))
            <<< SwitchRow() {
                $0.title = Localized("Separate Offline Group")
                $0.value = true
            }
            <<< SwitchRow() {
                $0.title = Localized("Sort by")
                $0.value = true
        }
    }


    func chatSection() -> Section {
        return Section(Localized("Chat"))
            <<< SwitchRow() {
                $0.title = Localized("Enter to Send")
                $0.value = true
            }
            <<< SwitchRow() {
                $0.title = Localized("Show unread message first")
                $0.value = true
        }
    }

    func othersSection() -> Section {
        return Section(
            header: Localized("Others"),
            footer: Localized("Some settings are applied after restart."))
            <<< PushRow<String>() {

                var languages = [String: String]()
                Localize.availableLanguages().forEach {
                    if $0 != "Base" {
                        languages[Localize.displayNameForLanguage($0)] = $0
                    }
                }

                $0.title = Localized("Language")
                $0.options = languages.keys.map { $0 }
                $0.value = Localize.displayNameForLanguage(Localize.currentLanguage())
                $0.onChange {
                    Localize.setCurrentLanguage(languages[$0.value!]!)
                    LeagueAssetManager.reloadChampionData(true)
                }
            }.onPresent { from, to in
                to.navigationItem.title = Localized("Language")
            }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        var insets : UIEdgeInsets
        if let tabController = tabBarController as? MainTabBarController, let adView = tabController.getAdView() {
            insets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length + adView.frame.height, 0)
        } else {
            insets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        }
        self.tableView!.contentInset = insets;
        self.tableView!.scrollIndicatorInsets = insets;
    }

    override func viewDidAppear(animated: Bool) {
        self.tableView?.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: .Top)
    }

    func multipleSelectorDone(item:UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
}


extension MoreViewController : UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController == self.tabBarController {
            self.tableView?.reloadData()
        }
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

extension MoreViewController {
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = Theme.TextColorSecondary
        }
    }
}