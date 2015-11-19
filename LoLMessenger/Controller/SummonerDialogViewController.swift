//
//  SummonerDialogViewController.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 2..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup
import ChameleonFramework
import JVFloatLabeledTextField

class SummonerDialogViewController : UIViewController {

    @IBOutlet weak var profileIcon: UIImageView!
    @IBOutlet weak var summonerName: UILabel!
    @IBOutlet weak var championScore: UILabel!
    @IBOutlet weak var masteryIcon: UIImageView!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var gameStatus: UILabel!
    @IBOutlet weak var elapsedTime: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var rosterNote: JVFloatLabeledTextView!

    @IBOutlet weak var summonerLevel: UILabel!
    @IBOutlet weak var summonerTierView: UIView!
    @IBOutlet weak var summonerTierLabel: UILabel!
    @IBOutlet weak var summonerTierImage: UIImageView!
    @IBOutlet weak var summonerTierRing: UIImageView!

    var hidesBottomButtons:Bool = false
    private var timer: NSTimer?

    var roster: LeagueRoster? {
        didSet {
            if isViewLoaded() {
                updateRoster()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.PrimaryColor
        view.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        view.layoutSubviews()
        profileIcon.layer.cornerRadius = profileIcon.frame.height/2
        profileIcon.layer.masksToBounds = true
        closeButton.addTarget(self, action: "dismiss", forControlEvents: UIControlEvents.TouchUpInside)
        chatButton.addTarget(self, action: "enterChat", forControlEvents: UIControlEvents.TouchUpInside)
        rosterNote.floatingLabel?.backgroundColor = UIColor.clearColor()
        rosterNote.delegate = self
        statusMessage.textColor = Theme.TextColorSecondary
        championScore.textColor = UIColor.init(
            fromImage: masteryIcon.image!,
            atPoint: CGPointMake(masteryIcon.bounds.width/2, masteryIcon.bounds.height/2))
        summonerTierLabel.textColor = championScore.textColor
        summonerLevel.textColor = championScore.textColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        updateRoster()

        if let backgroundView = popupController?.backgroundView {
             backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismiss"))
        }
    }

    override func viewWillLayoutSubviews() {
        if let _ = self.popupController {
            self.view.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 4, right: 12)
        } else {
            chatButton.hidden = hidesBottomButtons
            closeButton.hidden = hidesBottomButtons
        }
    }

    override func viewWillAppear(animated: Bool) {
        XMPPService.sharedInstance.roster()?.addDelegate(self)
    }

    override func viewWillDisappear(animated: Bool) {
        timer?.invalidate()
        timer = nil
    }

    override func viewDidDisappear(animated: Bool) {
        XMPPService.sharedInstance.roster()?.removeDelegate(self)
    }

    func updateRoster() {
        if let roster = roster {
            if let iconId = roster.profileIcon {
                LeagueAssetManager.drawProfileIcon(iconId, view: self.profileIcon)
            } else {
                self.profileIcon.image = UIImage(named: "profile_unknown")
            }
            summonerName.text = roster.username
            statusMessage.text = roster.statusMsg
            if let score = roster.championMasteryScore {
                championScore.hidden = false
                masteryIcon.hidden = false
                championScore.text = String(score)
            } else {
                masteryIcon.hidden = true
                championScore.hidden = true
            }

            if let tier = roster.rankedLeagueTier, let division = roster.rankedLeagueDivision,
                let medalImage = UIImage(named: "medals_\(tier.lowercaseString)") {
                    summonerTierImage.image = medalImage
                    summonerTierLabel.text = division
                    summonerTierRing.hidden = false
                    summonerTierView.hidden = false
                    summonerLevel.hidden = true

                    if tier == "CHALLENGER" || tier == "MASTER" {
                        summonerTierLabel.text = nil
                        summonerTierLabel.hidden = true
                    }

            } else if roster.level ?? 0 > 0 {
                summonerLevel.text = String(roster.level!)
                summonerLevel.hidden = false
                summonerTierView.hidden = true
                summonerTierRing.hidden = false
            } else {
                summonerLevel.hidden = true
                summonerTierView.hidden = true
                summonerTierRing.hidden = true
            }

            if let buddy = XMPPService.sharedInstance.roster()?.getRosterByJID(roster.userid) {
                if !buddy.subscribed {
                    rosterNote.hidden = true
                    chatButton.enabled = false
                } else {
                    rosterNote.hidden = false
                    chatButton.enabled = true
                }
            } else {
                rosterNote.hidden = true
                chatButton.setTitle("Add Friend", forState: .Normal)
                chatButton.removeTarget(self, action: "enterChat", forControlEvents: UIControlEvents.TouchUpInside)
                chatButton.addTarget(self, action: "addBuddy", forControlEvents: UIControlEvents.TouchUpInside)
            }

            gameStatus.text = roster.getCurrentGameStatus() ?? roster.getDisplayStatus(false)
            gameStatus.textColor = roster.getDisplayColor()
            elapsedTime.textColor = gameStatus.textColor

            if timer == nil {
                timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTimestamp", userInfo: nil, repeats: true)
            }
            timer?.fire()

            rosterNote.text = roster.note
        }
    }

    func updateTimestamp() {
        if roster?.status == .InGame {
            if roster?.elapsedTime >= 0 {
                let interval = Int((roster?.elapsedTime)!)
                let minutes = (interval / 60) % 60
                let seconds = interval % 60
                elapsedTime.text = String(format: "%02d:%02d", minutes, seconds)
            } else {
                elapsedTime.text = nil
            }
        } else {
            timer?.invalidate()
            timer = nil
            elapsedTime.text = nil
        }
    }

    func dismiss() {
        dismissWithCompletion()
    }

    func dismissWithCompletion(completion: dispatch_block_t? = nil) {
        if let popupController = popupController {
            if completion != nil {
                popupController.dismissWithCompletion(completion)
            } else {
                popupController.dismiss()
            }
        } else {
            dismissViewControllerAnimated(true, completion: completion)
        }
    }


    func dismissKeyboard() {
        view.endEditing(true)
    }

    func enterChat() {
        if let chatId = roster?.userid {
            dismissWithCompletion {
                NavigationUtils.navigateToChat(chatId: chatId)
            }
        }
    }

    func addBuddy() {
        if let summoner = roster {
            if summoner.jid().user.containsString("sum") {
                DialogUtils.alert(
                    "Add as Friend",
                    message: "Do you want to send a friend request to \(summoner.username)?",
                    handler: { _ in
                        XMPPService.sharedInstance.roster()?.addRoster(summoner)
                        DialogUtils.alert("Add as Friend", message: "Request Sent!")
                })
            } else {
                RiotACS.getSummonerByName(summonerName: summoner.username, region: XMPPService.sharedInstance.region!) {
                    if let summoner = $0 {
                        DialogUtils.alert(
                            "Add as Friend",
                            message: "Do you want to send a buddy request to \(summoner.username)?",
                            handler: { _ in XMPPService.sharedInstance.roster()?.addRoster(summoner) })
                    } else {
                        DialogUtils.alert(
                            "Error",
                            message: "Summoner named \(summoner.username) was not found")
                    }
                }
            }
        }
    }
}

extension SummonerDialogViewController : UITextViewDelegate {

    func textViewDidEndEditing(textView: UITextView) {
        setRosterNote()
    }

    func setRosterNote() {
        if let roster = self.roster {
            if roster.note != rosterNote.text {
                XMPPService.sharedInstance.roster()?.setNote(roster, note: rosterNote.text)
            }
        }
    }

}

extension SummonerDialogViewController : RosterDelegate {
    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster) {
        if from.userid == roster?.userid {
            self.roster = from
            updateRoster()
        }
    }
}