//
//  RecentChatTableCell.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 20..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import XMPPFramework

class RecentChatTableCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var stateIcon: UIImageView!
    @IBOutlet weak var alarmIcon: UIImageView!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var badge: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        badge.layer.masksToBounds = true
        badge.backgroundColor = Theme.AccentColor
        badge.layer.cornerRadius = badge.frame.height / 2

        alarmIcon.image = alarmIcon.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        alarmIcon.tintColor = Theme.TextColorSecondary
    }

    func setItem(chat: LeagueChat, roster: LeagueRoster?) {
        name.text = chat.name

        if let lastMessage = chat.lastMessage {
            message.text = lastMessage.body
        } else {
            message.text = nil
        }

        let datestr = chat.timestamp.format("MMM d")
        let today = NSDate().format("MMM d")
        if datestr == today {
            timestamp.text = chat.timestamp.format("HH:mm")
        } else {
            timestamp.text = datestr
        }

        if roster != nil {
            name.text = roster?.username
            stateIcon.image = roster?.getStatusIcon()
            if roster!.available {
                name.textColor = Theme.TextColorPrimary
                message.textColor = name.textColor
            } else {
                name.textColor = Theme.TextColorDisabled
                message.textColor = name.textColor
            }
            alarmIcon.hidden = !StoredProperties.AlarmDisabledJIDs.contains(roster!.userid)

        } else {
            stateIcon.image = PresenceShow.Unavailable.icon()
            name.textColor = Theme.TextColorDisabled
            message.textColor = name.textColor
            alarmIcon.hidden = true
        }

        if chat.unread > 0 {
            badge.text = String(chat.unread)
            badge.hidden = false
        } else {
            badge.hidden = true
        }
    }
}


class GroupChatTableCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var badge: UILabel!
    @IBOutlet weak var groupIndicator: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var participants: UILabel!
    @IBOutlet weak var alarmIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        badge.layer.masksToBounds = true
        badge.backgroundColor = Theme.AccentColor
        badge.layer.cornerRadius = badge.frame.height / 2

        groupIndicator.layer.masksToBounds = true
        groupIndicator.layer.cornerRadius = 4
        groupIndicator.backgroundColor = Theme.HighlightColor

        icon.image = icon.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        icon.tintColor = Theme.TextColorPrimary
        alarmIcon.image = alarmIcon.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        alarmIcon.tintColor = Theme.TextColorSecondary
    }

    func setItem(chat: LeagueChat, numParticipants: Int = 0) {
        name.text = chat.name

        if let lastMessage = chat.lastMessage {
            message.text = lastMessage.body
        } else {
            message.text = nil
        }

        let datestr = chat.timestamp.format("MMM d")
        let today = NSDate().format("MMM d")
        if datestr == today {
            timestamp.text = chat.timestamp.format("HH:mm")
        } else {
            timestamp.text = datestr
        }

        if numParticipants > 0 {
            participants.text = String(numParticipants)
            groupIndicator.hidden = false
        } else {
            groupIndicator.hidden = true
        }

        alarmIcon.hidden = !StoredProperties.AlarmDisabledJIDs.contains(chat.id)

        if chat.unread > 0 {
            badge.text = String(chat.unread)
            badge.hidden = false
        } else {
            badge.hidden = true
        }
    }
}

