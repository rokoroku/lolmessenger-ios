//
//  Theme.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 29..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import Eureka
import ChameleonFramework

struct Theme {
    static let PrimaryColor = UIColor.flatTealColorDark().darkenByPercentage(0.2)
    static let SecondaryColor = Theme.PrimaryColor.lightenByPercentage(0.04)
    static let HighlightColor = UIColor.flatTealColor()
    static let AccentColor = UIColor.flatRedColor()

    static let RedColor = UIColor.flatRedColorDark()
    static let YellowColor = UIColor.flatYellowColor()
    static let GreenColor = UIColor.greenColor().darkenByPercentage(0.3)

    static let TextColorWhite = UIColor.flatWhiteColor()
    static let TextColorBlack = UIColor.flatBlackColor()
    static let TextColorDisabled = UIColor.flatBlackColor().lightenByPercentage(0.4)
    static let TransculentBy5 = UIColor.init(white: 1, alpha: 0.025)
    static let TransculentBy10 = UIColor.init(white: 1, alpha: 0.075)

    static func applyGlobalTheme() {

        let navigationBar = UINavigationBar.appearance()
        navigationBar.barStyle = UIBarStyle.Black
        navigationBar.tintColor = Theme.TextColorWhite
        navigationBar.barTintColor = Theme.PrimaryColor
        navigationBar.translucent = false
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]

        let searchBar = UISearchBar.appearance()
        searchBar.tintColor = Theme.TextColorWhite
        searchBar.barTintColor = Theme.PrimaryColor
        searchBar.backgroundImage = UIImage()
        searchBar.translucent = true
        //searchBar.backgroundColor = Theme.PrimaryColor

        let tabBar = UITabBar.appearance()
        tabBar.tintColor = Theme.TextColorWhite
        tabBar.barTintColor = Theme.PrimaryColor
        tabBar.translucent = true

        let tableView = UITableView.appearance()
        tableView.backgroundColor = Theme.PrimaryColor
        tableView.separatorColor = Theme.PrimaryColor

        RecentChatTableCell.appearance().backgroundColor = Theme.TransculentBy5
        RosterTableChildCell.appearance().backgroundColor = Theme.TransculentBy5
        RosterTableGroupCell.appearance().backgroundColor = Theme.TransculentBy10
        BaseCell.appearance().backgroundColor = Theme.TransculentBy5
        BaseCell.appearance().textLabel?.textColor = Theme.TextColorWhite
        FloatLabelCell.appearance().textLabel?.textColor = Theme.TextColorWhite
        FloatLabelTextField.appearance().textColor = Theme.TextColorWhite

        let label = UILabel.appearance()
        label.textColor = UIColor.whiteColor()
        label.tintColor = UIColor.whiteColor()

        let tableCell = UITableViewCell.appearance()
        tableCell.tintColor = UIColor.lightGrayColor()

        let button = UIButton.appearance()
        button.setTitleColor(Theme.TextColorWhite, forState: .Normal)
        button.setTitleColor(Theme.TextColorDisabled, forState: .Disabled)
        button.setTitleColor(Theme.HighlightColor, forState: .Highlighted)
        button.setTitleColor(Theme.HighlightColor, forState: .Focused)
        button.tintColor = Theme.HighlightColor

        let switches = UISwitch.appearance()
        switches.tintColor = Theme.TextColorWhite
        switches.onTintColor = Theme.HighlightColor

        LabelRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
        TextRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
        SwitchRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
        CheckRow.defaultCellUpdate = { cell, row in
            cell.tintColor = Theme.TextColorWhite
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
        MultipleSelectorRow<String>.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
        PushRow<String>.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
        ButtonRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorWhite
            cell.detailTextLabel?.textColor = Theme.TextColorWhite
        }
    }

}
