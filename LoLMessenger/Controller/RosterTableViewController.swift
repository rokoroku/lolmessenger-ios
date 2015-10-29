//
//  RosterTableViewController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 9. 26..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import ChameleonFramework

class RosterTableViewController : UIViewController {
    
    @IBOutlet weak var tableView: YUTableView!

    var closeOtherNodes = false
    var insertRowAnimation: UITableViewRowAnimation = .Fade
    var deleteRowAnimation: UITableViewRowAnimation = .Fade

    var searchController: UISearchController?
    var isSearching: Bool {
        if searchController?.active ?? false {
            return !(searchController?.searchBar.text?.isEmpty ?? true)
        }
        return false
    }

    var allNodes = [YUTableViewNode]()
    var filteredNodes = [YUTableViewNode]()
    var activeNodes: [YUTableViewNode] {
        if isSearching {
            return filteredNodes
        } else {
            return allNodes
        }
    }

    var groupDictionary : [String:GroupNode]!

    var showOffline = true
    var separateOfflineGroup = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setTableProperties()
        setSearchController()
        XMPPService.sharedInstance.roster().addDelegate(self)
        navigationController?.hidesNavigationBarHairline = true
    }

    func setSearchController() {
        definesPresentationContext = true
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false

            self.tableView.tableHeaderView = controller.searchBar
            controller.searchBar.sizeToFit()
            return controller
        })()
    }

    func setTableProperties() {
        tableView.expandAllNodeAtFirstTime = true
        tableView.allowOnlyOneActiveNodeInSameLevel = closeOtherNodes
        tableView.insertRowAnimation = insertRowAnimation
        tableView.deleteRowAnimation = deleteRowAnimation
        tableView.setDelegate(self)
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Theme.PrimaryColor
    }

    override func viewWillLayoutSubviews() {
        let adjustForTabbarInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.tableView!.contentInset = adjustForTabbarInsets;
        self.tableView!.scrollIndicatorInsets = adjustForTabbarInsets;
    }

    override func viewWillAppear(animated: Bool) {
        // Called when the view is about to made visible. 
        reloadRosterNodes()
    }

    override func viewWillDisappear(animated: Bool) {
        // Called when the view is dismissed, covered or otherwise hidden.
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segue.EnterChat {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            let chatViewController = segue.destinationViewController as! ChatViewController

            // Get the cell that generated this segue.
            if let cell = sender as? RosterTableChildCell, let roster = cell.roster {
                let chat = XMPPService.sharedInstance.chat().getLeagueChatEntryByJID(roster.jid())!
                chatViewController.setInitialChatData(chat)
            }
        }
    }
}

extension RosterTableViewController {

    func reloadRosterNodes() {
        groupDictionary = [String:GroupNode]()

        let offlineGroup = GroupNode(name: "Offline")
        let rosterService = XMPPService.sharedInstance.roster()
        if let rosterList = rosterService.getRosterList() {
            for roster in rosterList {
                let rosterNode = RosterNode(roster: roster)
                var groupNode: GroupNode = getGroupNode(roster.group)
                if separateOfflineGroup && !roster.available {
                    groupNode = offlineGroup
                }
                groupNode.add(rosterNode)
            }
        }
        var result = Array(groupDictionary.values.sort { $0.name < $1.name })
        result.append(offlineGroup)

        allNodes = result
        tableView.setNodes(activeNodes)
    }

    func getGroupNode(name: String) -> GroupNode {
        var groupName = name
        if name == Constants.XMPP.DefaultGroup {
            groupName = NSLocalizedString("General", comment: "Default Group")
        }
        if let groupNode = groupDictionary[groupName] {
            return groupNode
        } else {
            let groupNode = GroupNode(name: groupName)
            groupDictionary[groupName] = groupNode
            return groupNode
        }
    }
}

extension RosterTableViewController: YUTableViewDelegate {

    func setContentsOfCell(cell: UITableViewCell, node: YUTableViewNode) {
        cell.selectionStyle = .None
        if let rosterNode = node as? RosterNode, let rosterCell = cell as? RosterTableChildCell {
            rosterCell.setData(rosterNode.roster)

        } else if let groupNode = node as? GroupNode, let groupCell = cell as? RosterTableGroupCell {
            groupCell.setTitle(groupNode.name)
        }
    }
    
    func heightForNode(node: YUTableViewNode) -> CGFloat? {
        if node.cellIdentifier == "GroupCell" {
            return 40.0;
        }
        return 58.0;
    }
    
}

extension RosterTableViewController: RosterDelegate {
    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster) {
        reloadRosterNodes()
    }

    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster) {
        
    }
    
    func didReceiveFriendSubscriptionDenial(sender: RosterService, from: LeagueRoster) {
        
    }
}

extension RosterTableViewController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if searchController.searchBar.superview?.isKindOfClass(UITableView) == false {
            searchController.searchBar.removeFromSuperview()
            self.tableView.addSubview(searchController.searchBar)
        }

        filteredNodes.removeAll(keepCapacity: false)
        for groupNode in allNodes {
            if groupNode.childNodes != nil {
                let filteredChildNodes = groupNode.childNodes.filter {
                    if let roster = $0.data as? LeagueRoster,
                        let keyword = searchController.searchBar.text {
                        return roster.username.stringByReplacingOccurrencesOfString(" ", withString: "").localizedCaseInsensitiveContainsString(keyword)
                    }
                    return false
                }
                if !filteredChildNodes.isEmpty {
                    let filteredGroupNode = GroupNode(name: groupNode.data as! String)
                    filteredGroupNode.childNodes = filteredChildNodes
                    filteredNodes.append(filteredGroupNode)
                }
            }
        }
        tableView.setNodes(activeNodes)
    }
}

class GroupNode : YUTableViewNode {
    init(name: String) {
        super.init(data: name, nodeId: name.hashValue, cellIdentifier: "GroupCell")
    }
    
    func add(rosterNode: RosterNode) {
        if childNodes == nil {
            childNodes = [rosterNode] as [RosterNode]
        } else {
            childNodes.append(rosterNode)
        }
    }

    var name: String {
        get {
            return data as! String;
        }
        set {
            data = name;
        }
    }
}

class RosterNode : YUTableViewNode {
    init(roster: LeagueRoster) {
        super.init(data: roster, nodeId: roster.getNumericUserId(), cellIdentifier: "RosterCell")
    }
    
    var roster: LeagueRoster {
        get {
            return data as! LeagueRoster
        }
        set {
            data = roster
        }
    }
}
