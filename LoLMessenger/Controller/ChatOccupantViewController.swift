//
//  ChatOccupantViewController.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 10..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup
import XMPPFramework

class ChatOccupantViewController: UITableViewController {

    var roomId: XMPPJID?

    var occupants = [LeagueRoster]()
    var numOfRows: Int {
        if isSearching {
            return filteredNodes.count
        } else {
            return occupants.count
        }
    }

    var searchController: UISearchController?
    var isSearching: Bool {
        if searchController?.active ?? false {
            return !(searchController?.searchBar.text?.isEmpty ?? true)
        }
        return false
    }

    var filteredNodes = [LeagueRoster]()
    var activeNodes: [LeagueRoster] {
        if isSearching {
            return filteredNodes
        } else {
            return occupants
        }
    }

    func reloadOccupants() {
        if let roomId = roomId, let occupantEntries = XMPPService.sharedInstance.chat()?.getOccupantsByJID(roomId) {
            occupants = occupantEntries
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Theme.PrimaryColor
        let adjustInsets = UIEdgeInsetsMake(16, 0, 0, 0)
        tableView.contentInset = adjustInsets;
        tableView.scrollIndicatorInsets = adjustInsets;
        setSearchController()
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

    override func viewWillAppear(animated: Bool) {
        // Load occupants
        reloadOccupants()

        // Add delegates
        XMPPService.sharedInstance.chat()?.addDelegate(self)
        if roomId != nil {
            XMPPService.sharedInstance.chat()?.joinRoomByJID(roomId!)
        }
    }


    override func viewDidDisappear(animated: Bool) {
        // Remove delegates
        if UIApplication.topViewController()?.isKindOfClass(STPopupContainerViewController) == false {
            XMPPService.sharedInstance.chat()?.removeDelegate(self)
        }
    }

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

// MARK: Table view delegate

extension ChatOccupantViewController {

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numOfRows
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "RosterCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! RosterTableChildCell

        // Fetches the appropriate meal for the data source layout.
        let occupant = activeNodes[indexPath.row]
        cell.setData(occupant)

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return !isSearching
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            //
        }
    }

}

extension ChatOccupantViewController : UISearchResultsUpdating, UISearchControllerDelegate {

    func didPresentSearchController(searchController: UISearchController) {
        if searchController.searchBar.superview?.isKindOfClass(UITableView) == false {
            //searchController.searchBar.removeFromSuperview()
            self.tableView.addSubview(searchController.searchBar)
        }
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredNodes = occupants.filter {
            if let keyword = searchController.searchBar.text {
                return $0.username.stringByReplacingOccurrencesOfString(" ", withString: "").localizedCaseInsensitiveContainsString(keyword)
            }
            return false
        }
        tableView.reloadData()
    }
}

extension ChatOccupantViewController : ChatDelegate {

    func didReceiveOccupantUpdate(sender: ChatService, from: LeagueChat, occupant: LeagueRoster) {
        if from.jid.user == self.roomId {
            if self.occupants.isEmpty {
                self.reloadOccupants()
            } else {
                Async.background {
                    let leaved = !occupant.available
                    var index = 0
                    for entry in self.occupants {
                        index++
                        if entry.username == occupant.username {
                            entry.parsePresence(occupant.getPresenceElement())
                            break
                        }
                    }
                    if leaved {
                        self.occupants.removeAtIndex(index)
                    }
                    Async.main {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}