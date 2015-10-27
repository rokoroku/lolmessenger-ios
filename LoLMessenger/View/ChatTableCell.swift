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

    static var zeroSize: CGSize = CGSizeMake(0, 0)

    @IBOutlet weak var profileIcon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var balloonImage: BalloonView!

    var initialSize: CGSize?
    var balloonNinePatch: TUNinePatchProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        backgroundColor = UIColor.clearColor()

        body.text = nil
        body.sizeToFit()
        body.updateConstraints()

        balloonImage.sizeToFit()
        balloonImage.updateConstraints()
        balloonImage.addSubview(body)

        if profileIcon != nil {
            profileIcon.layer.cornerRadius = 2.0
            profileIcon.layer.masksToBounds = true
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        body.text = nil
        body.sizeToFit()
        balloonImage.setNeedsDisplay()
        balloonImage.invalidateIntrinsicContentSize()
    }

    func setItem(roster: LeagueRoster?, message: LeagueMessage.RawData) {
        if profileIcon != nil {
            if let iconId = roster?.profileIcon {
                profileIcon.image = UIImage(named: "profile_\(iconId)") ?? UIImage(named: "profile_unknown")
            } else {
                profileIcon.image = UIImage(named: "profile_unknown")
            }
        }
        if name != nil {
            name.text = message.nick
        }
        if body != nil {
            body.text = message.body
        }
        if balloonImage != nil {
            balloonImage.type = message.isMine ? .Right : .Left
            balloonImage.invalidateIntrinsicContentSize()
            balloonImage.setNeedsDisplay()
        }
        if timestamp != nil {
            timestamp.text = message.timestamp.format("HH:mm")
        }
    }

}