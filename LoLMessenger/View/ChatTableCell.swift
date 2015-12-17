//
//  ChatTableCell.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 21..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import XMPPFramework
import Tortuga22_NinePatch

class BalloonView: UIView {
    static var leftNinePatch: TUNinePatchProtocol = TUNinePatch.ninePatchWithNinePatchImage(UIImage(named: "balloon_left.9"))
    static var rightNinePatch: TUNinePatchProtocol = TUNinePatch.ninePatchWithNinePatchImage(UIImage(named: "balloon_right.9"))

    enum Type {
        case Left
        case Right
    }

    var type: Type = .Left
    var ninePatch: TUNinePatchProtocol {
        switch (type) {
        case .Left: return BalloonView.leftNinePatch
        case .Right: return BalloonView.rightNinePatch
        }
    }

    override func drawRect(rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            CGContextClearRect(context, rect);
            ninePatch.imageOfSize(rect.size).drawInRect(rect)
        }
    }
}

class ChatTableCell: UITableViewCell {

    @IBOutlet weak var profileIcon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var balloonImage: BalloonView!

    var roster: LeagueRoster?
    var message: LeagueMessage.RawData?

    private var initialSize: CGSize?
    private var balloonNinePatch: TUNinePatchProtocol?
    private var dateChangedLabel: UILabel?

    var showsDateChangedBar: Bool {
        get {
            return dateChangedLabel != nil || dateChangedLabel?.superview == nil
        }
        set {
            if (dateChangedLabel != nil && !newValue) {
                dateChangedLabel?.removeFromSuperview()
                dateChangedLabel = nil
                contentView.updateConstraints()

            } else if (dateChangedLabel == nil && newValue) {
                if let date = message?.timestamp {
                    dateChangedLabel = UILabel()
                    dateChangedLabel!.layer.cornerRadius = 2.0
                    dateChangedLabel!.layer.masksToBounds = true
                    dateChangedLabel!.backgroundColor = Theme.HighlightColor
                    dateChangedLabel!.textColor = Theme.TextColorPrimary
                    dateChangedLabel!.font = dateChangedLabel!.font.fontWithSize(12)
                    dateChangedLabel!.text = "  \((date.formatDate(.LongStyle))!)  "
                    dateChangedLabel!.sizeToFit()
                    contentView.addSubview(dateChangedLabel!)
                    contentView.addConstraint(dateChangedLabel!.constraintWithAttribute(.CenterX, .Equal, to: contentView))
                    contentView.addConstraints(
                        NSLayoutConstraint.constraintsWithVisualFormat(
                            "V:|-(4@1000)-[label(height)]-(topmargin@1000)-[topview]",
                            options: [],
                            metrics: [
                                "height": 20,
                                "topmargin": profileIcon != nil || name != nil ? 8 : 16
                            ],
                            views: [
                                "topview": profileIcon != nil ? profileIcon : name != nil ? name : body,
                                "label": dateChangedLabel!
                            ]))
                    
                    contentView.updateConstraints()
                    contentView.invalidateIntrinsicContentSize()
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        backgroundColor = UIColor.clearColor()

        body.text = nil
        body.sizeToFit()
        body.updateConstraints()
        body.textColor = UIColor.flatBlackColor()

        balloonImage.sizeToFit()
        balloonImage.updateConstraints()
        balloonImage.addSubview(body)

        if profileIcon != nil {
            profileIcon.layer.cornerRadius = 2.0
            profileIcon.layer.masksToBounds = true

            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: Selector("openSummonerDialog"))
            singleTapRecognizer.numberOfTapsRequired = 1
            profileIcon.userInteractionEnabled = true
            profileIcon.addGestureRecognizer(singleTapRecognizer)
        }
    }

    func openSummonerDialog() {
        UIApplication.topViewController()?.performSegueWithIdentifier("SummonerModal", sender: self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        body.text = nil
        body.sizeToFit()
        balloonImage.setNeedsDisplay()
        balloonImage.invalidateIntrinsicContentSize()
    }

    func setItem(roster: LeagueRoster?, message: LeagueMessage.RawData, dateChanged: Bool = false) {
        self.roster = roster
        self.message = message
        let isActive = roster?.available ?? false

        if profileIcon != nil {
            if let iconId = roster?.profileIcon {
                LeagueAssetManager.drawProfileIcon(iconId, view: self.profileIcon)
            } else {
                self.profileIcon.image = UIImage(named: "profile_unknown")
            }
            profileIcon.tag = roster?.getNumericUserId() ?? -1
        }

        if name != nil {
            name.text = message.nick
            if isActive {
                name.textColor = Theme.TextColorPrimary
            } else {
                name.textColor = Theme.TextColorDisabled
            }
        }

        showsDateChangedBar = dateChanged

        body.text = message.body
        timestamp.text = message.timestamp.format("HH:mm")

        body.sizeToFit()
        balloonImage.type = message.isMine ? .Right : .Left
        balloonImage.setNeedsDisplay()
        balloonImage.invalidateIntrinsicContentSize()
    }
}