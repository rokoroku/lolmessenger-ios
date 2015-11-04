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
    @IBOutlet weak var childCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.childCountLabel.textColor = Theme.TextColorSecondary
    }
    
    func setData (groupNode: GroupNode) {
        self.label.text = groupNode.data as? String ?? "Unknown";
        if groupNode.numOfTotalRoster > 0 {
            let childCount = groupNode.childNodes != nil ? groupNode.childNodes.count : 0
            childCountLabel.text = "(\(childCount)/\(groupNode.numOfTotalRoster))"
        } else {
            childCountLabel.text = nil
        }
        if groupNode.isActive {
            indicator.image = UIImage(named: "collapsed_arrow")?
                .tint(Theme.TextColorPrimary, blendMode: .Overlay)
        } else {
            indicator.image = UIImage(named: "expand_arrow")?
                .tint(Theme.TextColorPrimary, blendMode: .Overlay)
        }
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
        self.status.textColor = roster.getDisplayColor()
        self.indicator.image = roster.getStatusIcon()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

