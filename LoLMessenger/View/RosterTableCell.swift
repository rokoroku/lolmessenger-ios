//
//  RosterTableCell.swift
//  LoLMessenger
//
//  Created by 김영록 on 2015. 9. 26..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class RosterTableGroupCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setTitle (text: String) {
        self.label.text = text;
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

class RosterTableChildCell: UITableViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var indicator: UIImageView!

    var roster: LeagueRoster?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        self.icon.layer.cornerRadius = 4.0
    }

    func setData(roster: LeagueRoster) {
        self.roster = roster
        self.name.text = roster.username
        self.icon.image = roster.getProfileIcon()
        self.status.text = roster.getDisplayStatus()
        self.indicator.image = roster.getStatusIcon()

        switch(roster.show) {
        case .Chat: status.textColor = Theme.GreenColor; break;
        case .Dnd: status.textColor = Theme.YellowColor; break;
        case .Away: status.textColor = Theme.RedColor; break;
        default: status.textColor = Theme.TextColorWhite; break;
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

