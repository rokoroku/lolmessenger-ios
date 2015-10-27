//
//  RosterTableViewController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 9. 26..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class RosterTableViewController : UIViewController {
    
    @IBOutlet weak var tableView: YUTableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var closeOtherNodes = false
    var insertRowAnimation: UITableViewRowAnimation = .Fade
    var deleteRowAnimation: UITableViewRowAnimation = .Fade
    
    var allNodes : [YUTableViewNode]!
    var groupDictionary : [String:GroupNode]!

    var showOffline = true
    var separateOfflineGroup = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTableProperties();
        XMPPService.sharedInstance.roster().addDelegate(self)
    }
    
    func setTableProperties () {
        tableView.expandAllNodeAtFirstTime = true;
        tableView.allowOnlyOneActiveNodeInSameLevel = closeOtherNodes;
        tableView.insertRowAnimation = insertRowAnimation;
        tableView.deleteRowAnimation = deleteRowAnimation;
        tableView.setDelegate(self);
        
        allNodes = loadRosterNodes();
        tableView.setNodes(allNodes);
    }
    
    func setTableViewSettings (closeOtherNodes closeOtherNodes: Bool, insertAnimation: UITableViewRowAnimation, deleteAnimation: UITableViewRowAnimation) {
        self.closeOtherNodes = closeOtherNodes;
        self.insertRowAnimation = insertAnimation;
        self.deleteRowAnimation = deleteAnimation;
    }
    
    func loadRosterNodes () -> [YUTableViewNode] {
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
        return result;
    }
    
    func getGroupNode(name: String) -> GroupNode {
        var groupName = name
        if name == Constants.XMPP.DefaultGroup {
            groupName = "일반"
        }
        if let groupNode = groupDictionary[groupName] {
            return groupNode
        } else {
            let groupNode = GroupNode(name: groupName)
            groupDictionary[groupName] = groupNode
            return groupNode
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    override func viewWillLayoutSubviews() {
        let adjustForTabbarInsets = UIEdgeInsetsMake(0, 0, self.bottomLayoutGuide.length, 0)
        self.tableView!.contentInset = adjustForTabbarInsets;
        self.tableView!.scrollIndicatorInsets = adjustForTabbarInsets;
    }

    override func viewWillAppear(animated: Bool) {
        // Called when the view is about to made visible. 
        loadRosterNodes()
    }

    override func viewWillDisappear(animated: Bool) {
        // Called when the view is dismissed, covered or otherwise hidden.
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
            return 44.0;
        }
        return 56.0;
    }
    
}

extension RosterTableViewController: RosterDelegate {
    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster) {
        if tableView != nil {
            allNodes = loadRosterNodes()
            tableView.setNodes(allNodes)
        }
    }
    
    func didReceiveFriendSubscription(sender: RosterService, from: LeagueRoster) {
        
    }
    
    func didReceiveFriendSubscriptionDenial(sender: RosterService, from: LeagueRoster) {
        
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
        super.init(data: roster, nodeId: roster.getNumericUserid(), cellIdentifier: "RosterCell")
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