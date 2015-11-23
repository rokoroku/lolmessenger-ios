//
//  RosterTableViewController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 9. 26..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup
import ChameleonFramework

class RosterTableViewController : UIViewController {
    
    @IBOutlet weak var tableView: YUTableView!
    @IBOutlet weak var addButton: UIBarButtonItem!

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

        navigationController?.delegate = self
        navigationController?.hidesNavigationBarHairline = true
    }

    func updateLocale() {
        navigationItem.title = Localized("Friends")
        if tabBarItem != nil { tabBarItem.title = Localized("Friends") }
    }

    func setSearchController() {
        //definesPresentationContext = true
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.delegate = self

            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()

        self.tableView.reloadData()
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
        super.viewWillLayoutSubviews()
        let adjustForTabbarInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.tableView!.contentInset = adjustForTabbarInsets;
        self.tableView!.scrollIndicatorInsets = adjustForTabbarInsets;
    }

    override func viewWillAppear(animated: Bool) {
        // Called when the view is about to made visible. 
        updateLocale()
        reloadRosterNodes()
        XMPPService.sharedInstance.roster()?.addDelegate(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateLocale", name: LCLLanguageChangeNotification, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        if UIApplication.topViewController()?.isKindOfClass(STPopupContainerViewController) == false {
            XMPPService.sharedInstance.roster()?.removeDelegate(self)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: LCLLanguageChangeNotification, object: nil)
        }
    }

    @IBAction func addAction(sender: AnyObject) {
        DialogUtils.input(
            Localized("Add as Friend"),
            message: Localized("Please enter summoner name you want to add"),
            placeholder: Localized("Summoner Name")) {
            if let name = $0 {
                RiotACS.getSummonerByName(summonerName: name, region: XMPPService.sharedInstance.region!) {
                    if let summoner = $0 {
                        DialogUtils.alert(
                            Localized("Add as Friend"),
                            message: Localized("Do you want to send a buddy request to %1$@?", args: summoner.username),
                            handler: { _ in
                                XMPPService.sharedInstance.roster()?.addRoster(summoner)
                                DialogUtils.alert(Localized("Add as Friend"), message: Localized("Request Sent!"))
                        })
                    } else {
                        DialogUtils.alert(
                            Localized("Error"),
                            message: Localized("Summoner named %1$@ was not found", args: name))
                    }
                }
            }
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // Get the cell that generated the segue.
        var roster: LeagueRoster!

        if let param = sender as? LeagueRoster {
            roster = param
        } else if let cell = sender as? RosterTableChildCell, let param = cell.roster {
            roster = param
        }

        if roster != nil {
            if let chatViewController = segue.destinationViewController as? ChatViewController,
                let chat = XMPPService.sharedInstance.chat()?.getLeagueChatEntryByJID(roster.jid()) {
                    chatViewController.setInitialChatData(chat)
            }

            else if let summonerViewController = segue.destinationViewController as? SummonerDialogViewController {
                summonerViewController.roster = roster
                if segue.identifier == "SummonerModalPreview" {
                    summonerViewController.hidesBottomButtons = true

                } else if segue.identifier == "SummonerModalCommit" {
                    if let popupSegue = segue as? PopupSegue {
                        popupSegue.shouldPerform = false
                        Async.main(after: 0.1) {
                            self.performSegueWithIdentifier("EnterChat", sender: sender)
                        }
                    }
                }
            }
        }
    }
}

extension RosterTableViewController : UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController == self.tabBarController {
            reloadRosterNodes()
        }
    }
}

extension RosterTableViewController {

    func reloadRosterNodes() {
        groupDictionary = [String:GroupNode]()

        let offlineGroup = GroupNode(name: Constants.XMPP.OfflineGroup)
        let rosterService = XMPPService.sharedInstance.roster()
        if let rosterList = rosterService?.getRosterList() {
            for roster in rosterList {
                let rosterNode = RosterNode(roster: roster)
                var groupNode: GroupNode = getGroupNode(roster.group)
                groupNode.numOfTotalRoster++
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
            groupName = Constants.XMPP.GeneralGroup
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
            groupCell.setData(groupNode)
        }
    }
    
    func heightForNode(node: YUTableViewNode) -> CGFloat? {
        if node.cellIdentifier == "GroupCell" {
            return 40.0;
        }
        return 58.0;
    }

    func didSelectNode(node: YUTableViewNode, indexPath: NSIndexPath) {
        if let _ = node as? GroupNode, let cell = tableView.cellForRowAtIndexPath(indexPath) as? RosterTableGroupCell {
            cell.indicator.rotate180Degrees()
        }
    }

    func didMoveNode(node: YUTableViewNode, fromGroup: YUTableViewNode, toGroup: YUTableViewNode) {
        if let group = toGroup as? GroupNode, let groupName = group.data as? String {
            if groupName == Constants.XMPP.OfflineGroup {
                reloadRosterNodes()
            } else {

            }
        }
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

extension RosterTableViewController: UISearchResultsUpdating, UISearchControllerDelegate {

    func didPresentSearchController(searchController: UISearchController) {
        if searchController.searchBar.superview?.isKindOfClass(UITableView) == false {
            //searchController.searchBar.removeFromSuperview()
            self.tableView.addSubview(searchController.searchBar)
       }
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {

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

    var numOfTotalRoster = 0

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
