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
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var badge: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        badge.layer.masksToBounds = true
        badge.layer.cornerRadius = badge.frame.height / 2
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setItem(chat: LeagueChat, roster: LeagueRoster?) {
        name.text = chat.name

        if let lastMessage = chat.lastMessage {
            message.text = lastMessage.body
        } else {
            message.text = nil
        }

        timestamp.text = chat.timestamp.format("HH:mm")

        if roster != nil {
            name.text = roster?.username
            stateIcon.image = roster?.getStatusIcon()
        } else {
            stateIcon.image = PresenceShow.Unavailable.icon()
        }

        if chat.unread > 0 {
            badge.text = String(chat.unread)
            badge.hidden = false
        } else {
            badge.hidden = true
        }
    }
}

