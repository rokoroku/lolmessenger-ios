//
//  GroupChatTitleView.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 12..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class GroupChatTitleView: UIView {

    internal required init(title: String, subtitle: String? = nil) {
        super.init(frame: CGRectZero)
        titleLabel.text = title
        detailLabel.text = subtitle

        self.autoresizesSubviews = true
        self.autoresizingMask = .FlexibleHeight
        self.translatesAutoresizingMaskIntoConstraints = true

        self.addSubview(titleLabel)
        self.addSubview(detailLabel)

        let views = [
            "titleLabel": titleLabel,
            "detailLabel": detailLabel
        ]
        self.addConstraints(NSLayoutConstraint.defaultConstraintsWithVisualFormat("V:[titleLabel]-(-3)-[detailLabel]", views: views))
        self.addConstraint(titleLabel.constraintWithAttribute(.CenterY, .Equal, to: self, multiplier: 1, constant: -5))
        self.addConstraint(titleLabel.constraintWithAttribute(.CenterX, .Equal, to: self))
        self.addConstraint(detailLabel.constraintWithAttribute(.CenterX, .Equal, to: self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeToFit() {
        titleLabel.sizeToFit()
        detailLabel.sizeToFit()
        super.sizeToFit()
    }

    internal let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFontOfSize(17)
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(11)
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

}
