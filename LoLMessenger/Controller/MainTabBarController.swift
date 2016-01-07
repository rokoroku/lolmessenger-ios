//
//  MainTabBarController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 20..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup

class MainTabBarController : UITabBarController {

    var contentViewFrame : CGRect?
    var isAdActivated: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        self.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateLocale", name: LCLLanguageChangeNotification, object: nil)

        if let roster = XMPPService.sharedInstance.roster() {
            updateRosterBadge(roster)
        }
        if let chat = XMPPService.sharedInstance.chat() {
            updateChatBadge(chat)
        }

        AppDelegate.addDelegate(self)

        Async.main(after: 2) {
            self.showAd()
        }
        updateLocale()
    }

    deinit {
        AppDelegate.removeDelegate(self)
    }

    func updateLocale() {
        if let items = self.tabBar.items {
            items[0].title = Localized("Friends")
            items[1].title = Localized("Chat")
            items[2].title = Localized("Setting")
        }
    }

    override func viewWillAppear(animated: Bool) {
        // Called when the view is about to made visible.
        XMPPService.sharedInstance.roster()?.addDelegate(self)
        XMPPService.sharedInstance.chat()?.addDelegate(self)

        if let presentedViewController = self.selectedViewController {
            self.tabBarController(self, didSelectViewController: presentedViewController)
        } else {
            self.navigationItem.title = Localized("Friends")
        }
    }

    override func viewDidAppear(animated: Bool) {
        if let presentedViewController = self.selectedViewController {
            self.tabBarController(self, didSelectViewController: presentedViewController)
        }
        Async.main(after: 1) {
            self.startAdRequest()
        }
    }

    override func viewDidDisappear(animated: Bool) {
        if !(UIApplication.topViewController() is STPopupContainerViewController) {
            XMPPService.sharedInstance.chat()?.removeDelegate(self)
            XMPPService.sharedInstance.roster()?.removeDelegate(self)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: LCLLanguageChangeNotification, object: nil)
        }
    }

    func updateRosterBadge(rosterService: RosterService) {
        if let viewControllers = viewControllers {
            for viewController in viewControllers {
                if viewController.restorationIdentifier == "RosterTableViewController" {
                    let value = rosterService.getNumOfSubscriptionRequests()
                    viewController.tabBarItem?.badgeValue = value > 0 ? String(value) : nil
                    return
                }
            }
        }
    }

    func updateChatBadge(chatService: ChatService) {
        if let viewControllers = viewControllers {
            for viewController in viewControllers {
                if viewController.restorationIdentifier == "RecentChatViewController" {
                    let value = chatService.getNumOfUnreadMessages()
                    viewController.tabBarItem?.badgeValue = value > 0 ? String(value) : nil
                    return
                }
            }
        }
    }

}

extension MainTabBarController : AdMixerViewDelegate, BackgroundDelegate {

    func showAd() {
        if view.viewWithTag(11) == nil {
            let bounds = UIScreen.mainScreen().bounds
            let bannerView = AdMixerView(frame: CGRectMake(0.0, bounds.size.height, bounds.width, 50.0))
            bannerView.backgroundColor = UIColor.init(patternImage: UIImage(named: "default_banner_bg")!)
            bannerView.tag = 11
            bannerView.clipsToBounds = true

            self.view.addSubview(bannerView)
            startAdRequest()
        }
    }

    func startAdRequest() {
        if let banner = view.viewWithTag(11) as? AdMixerView where !isAdActivated {
            isAdActivated = true

            let adInfo = AdMixerInfo()
            adInfo.axKey = "3l188e4t"
            adInfo.rtbVerticalAlign = AdMixerRTBVAlignCenter
            adInfo.rtbBannerHeight = AdMixerRTBBannerHeightFixed
            banner.delegate = self
            banner.startWithAdInfo(adInfo, baseViewController: self)
        }
    }

    func stopAdRequest(layout: Bool = false) {
        if let banner = view.viewWithTag(11) as? AdMixerView where isAdActivated {
            banner.stop()
            isAdActivated = false

            if layout {
                layoutBanner(false)
            }
        }
    }

    func didEnterBackground(sender: UIApplication) {
        stopAdRequest(true)
    }

    func didBecomeActive(sender: UIApplication) {
        Async.main(after: 1) {
            self.startAdRequest()
        }
    }

    @objc func onSucceededToReceiveAd(adView: AdMixerView!) {
        #if DEBUG
            print("receive AD from \(adView.currentAdapterName())")
        #endif
        if isVisible() {
            layoutBanner()
        } else {
            stopAdRequest(true)
        }
    }

    @objc func onFailedToReceiveAd(adView: AdMixerView!, error: AXError!) {
        #if DEBUG
            print("fail to receive \(adView.currentAdapterName()), \(error)")
        #endif
        layoutBanner(false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.bringSubviewToFront(self.tabBar)
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        Async.main(after:0.1) { self.layoutBanner() }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        Async.main(after:0.1) { self.layoutBanner() }
    }

    private func layoutBanner(var show: Bool = true) {
        if let banner = view.viewWithTag(11) as? AdMixerView {

            let adapter: String? = banner.currentAdapterName()
            if selectedViewController is MoreViewController {
                show = false
            } else if adapter == nil || adapter == "ax_default" {
                show = false
            }

            let bounds = UIScreen.mainScreen().bounds
            let bannerSize = banner.sizeThatFits(bounds.size)

            var bannerFrame = banner.frame
            bannerFrame.width = bounds.width
            bannerFrame.height = bannerSize.height

            //let bannerItem = banner.subviews.first where !bannerItem.subviews.isEmpty &&
            if isAdActivated && show {
                bannerFrame.origin.y = self.tabBar.frame.y - bannerSize.height
            } else {
                bannerFrame.origin.y = bounds.size.height
            }

            self.view.bringSubviewToFront(self.tabBar)
            UIView.animateWithDuration(0.25,
                animations: {
                    banner.frame = bannerFrame
                },
                completion: { _ in
                    self.selectedViewController?.viewWillLayoutSubviews()
            })
        }
    }

    func getAdView() -> UIView? {
        if let banner = view.viewWithTag(11) as? AdMixerView {
            let adapter: String? = banner.currentAdapterName()
            return (adapter != nil && adapter != "ax_default") ? banner.subviews.first : nil
        }
        return nil
    }
}

extension MainTabBarController : UITabBarControllerDelegate {
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if let navigationItem: UINavigationItem = viewController.navigationItem {
            self.navigationItem.title = navigationItem.title
            self.navigationItem.setLeftBarButtonItems(navigationItem.leftBarButtonItems, animated: false)
            self.navigationItem.setRightBarButtonItems(navigationItem.rightBarButtonItems, animated: false)
        }
        self.layoutBanner()
    }
}

extension MainTabBarController : ChatDelegate, RosterDelegate {
    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster) {
        if selectedViewController?.isKindOfClass(RosterTableViewController) == false {
            updateRosterBadge(sender)
        }
    }

    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        if selectedViewController?.isKindOfClass(RecentChatViewController) == false {
            updateChatBadge(sender)
        }
    }
}