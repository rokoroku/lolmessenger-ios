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
    var initialSize: CGSize?
    var balloonNinePatch: TUNinePatchProtocol?

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
        balloonImage.invalidateIntrinsicContentSize()
        balloonImage.setNeedsDisplay()
    }

    func setItem(roster: LeagueRoster?, message: LeagueMessage.RawData) {
        self.roster = roster

        if profileIcon != nil {
            profileIcon.image = roster?.getProfileIcon() ?? UIImage(named: "profile_unknown")
            profileIcon.tag = roster?.getNumericUserId() ?? -1
        }
        if name != nil {
            name.text = message.nick
            if roster?.show != .Unavailable {
                name.textColor = Theme.TextColorPrimary
            } else {
                name.textColor = Theme.TextColorDisabled
            }
        }
        body.text = message.body
        timestamp.text = message.timestamp.format("HH:mm")
        balloonImage.type = message.isMine ? .Right : .Left
    }

}