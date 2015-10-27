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
    
    func setData (image: UIImage?, name: String, status: String) {
        self.icon.image = image
        self.name.text = name
        self.status.text = status
    }

    func setData (roster: LeagueRoster) {
        self.roster = roster

        let image = UIImage(named: "profile_\(roster.profileIcon)")
        let name = roster.username
        let status = roster.getDisplayStatus()

        setData(image ?? UIImage(named: "profile_unknown"), name: name, status: status)
        indicator.image = roster.show.icon()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

