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
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        updateRoster()
    }

    override func viewWillLayoutSubviews() {
        if let _ = self.popupController {
            self.view.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        } else {
            chatButton.hidden = hidesBottomButtons
            closeButton.hidden = hidesBottomButtons
        }
    }

    override func viewWillDisappear(animated: Bool) {
        timer?.invalidate()
        timer = nil
    }

    func updateRoster() {
        if let roster = roster {
            print(roster.description)
            profileIcon.image = roster.getProfileIcon()
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
        print("updateTimestamp")
        if roster?.status == .InGame {
            if let interval = roster?.elapsedTime {
                let minutes = (Int(interval) / 60) % 60
                let seconds = Int(interval) % 60
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
}

extension SummonerDialogViewController : UITextViewDelegate {

    func textViewDidEndEditing(textView: UITextView) {
        setRosterNote()
    }

    func setRosterNote() {
        if let _ = roster {
            XMPPService.sharedInstance.roster().setNote(roster!, note: rosterNote.text)
        }
    }

}