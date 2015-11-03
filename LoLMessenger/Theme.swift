//
//  Theme.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 29..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import Eureka
import JVFloatLabeledTextField
import ChameleonFramework

struct Theme {
    static let PrimaryColor = UIColor.flatTealColorDark().darkenByPercentage(0.2)
    static let SecondaryColor = Theme.PrimaryColor.lightenByPercentage(0.04)
    static let HighlightColor = UIColor.flatTealColor()
    static let AccentColor = UIColor.flatRedColor()

    static let RedColor = UIColor.flatRedColor().darkenByPercentage(0.1)
    static let GreenColor = UIColor.greenColor().darkenByPercentage(0.25)
    static let YellowColor = UIColor.flatYellowColor()

    static let TextColorPrimary = ContrastColorOf(PrimaryColor, true)
    static let TextColorSecondary = TextColorPrimary.colorWithAlphaComponent(0.55)
    static let TextColorBlack = UIColor.flatBlackColor()
    static let TextColorDisabled = UIColor.flatBlackColor().lightenByPercentage(0.4)

    static let TransculentBy5 = UIColor.init(white: 1, alpha: 0.025)
    static let TransculentBy10 = UIColor.init(white: 1, alpha: 0.075)

    static func applyGlobalTheme() {

        let navigationBar = UINavigationBar.appearance()
        navigationBar.barStyle = UIBarStyle.Black
        navigationBar.tintColor = UIColor.init(contrastingBlackOrWhiteColorOn: PrimaryColor, isFlat: true)
        navigationBar.barTintColor = Theme.PrimaryColor
        navigationBar.translucent = false
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]

        let searchBar = UISearchBar.appearance()
        searchBar.tintColor = Theme.TextColorPrimary
        searchBar.barTintColor = Theme.PrimaryColor
        searchBar.backgroundImage = UIImage()
        searchBar.translucent = true

        let tabBar = UITabBar.appearance()
        tabBar.tintColor = Theme.TextColorPrimary
        tabBar.barTintColor = Theme.PrimaryColor
        tabBar.translucent = true

        let tableView = UITableView.appearance()
        tableView.backgroundColor = Theme.PrimaryColor
        tableView.separatorColor = Theme.PrimaryColor

        let tableCell = UITableViewCell.appearance()
        tableCell.tintColor = UIColor.lightGrayColor()

        RecentChatTableCell.appearance().backgroundColor = Theme.TransculentBy5
        RosterTableChildCell.appearance().backgroundColor = Theme.TransculentBy5
        RosterTableGroupCell.appearance().backgroundColor = Theme.TransculentBy10

        let label = UILabel.appearance()
        label.textColor = ContrastColorOf(PrimaryColor, true)
        label.tintColor = label.textColor

        let textField = UITextField.appearance()
        textField.textColor = Theme.TextColorPrimary
        textField.tintColor = Theme.HighlightColor

        let textView = UITextView.appearance()
        textView.textColor = Theme.TextColorPrimary
        textView.tintColor = Theme.HighlightColor

        let floatLabeledTextView = JVFloatLabeledTextView.appearance()
        floatLabeledTextView.textColor = Theme.TextColorPrimary
        floatLabeledTextView.placeholderTextColor = Theme.TextColorSecondary
        floatLabeledTextView.floatingLabelTextColor = Theme.TextColorSecondary
        floatLabeledTextView.floatingLabelActiveTextColor = Theme.HighlightColor.lightenByPercentage(0.4)
        floatLabeledTextView.tintColor = Theme.HighlightColor.lightenByPercentage(0.4)

        let button = UIButton.appearance()
        button.setTitleColor(Theme.TextColorPrimary, forState: .Normal)
        button.setTitleColor(Theme.TextColorDisabled, forState: .Disabled)
        button.setTitleColor(Theme.HighlightColor, forState: .Highlighted)
        if #available(iOS 9.0, *) {
            button.setTitleColor(Theme.HighlightColor, forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.tintColor = Theme.HighlightColor

        let switches = UISwitch.appearance()
        switches.tintColor = Theme.TextColorSecondary
        switches.onTintColor = Theme.HighlightColor

        LabelRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        TextRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        SwitchRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        CheckRow.defaultCellUpdate = { cell, row in
            cell.tintColor = Theme.TextColorPrimary
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        MultipleSelectorRow<String>.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        PushRow<String>.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        ButtonRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = Theme.TextColorPrimary
            cell.detailTextLabel?.textColor = Theme.TextColorPrimary
        }
        BaseCell.appearance().backgroundColor = Theme.TransculentBy5
        BaseCell.appearance().textLabel?.textColor = Theme.TextColorPrimary
        FloatLabelCell.appearance().textLabel?.textColor = Theme.TextColorPrimary
        FloatLabelTextField.appearance().textColor = Theme.TextColorPrimary
        FloatLabelTextField.appearance().tintColor = Theme.HighlightColor.lightenByPercentage(0.4)
    }

}
