//
//  RecentChatViewController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 20..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import ChameleonFramework

class RecentChatViewController : UITableViewController {

    var chats = [LeagueChat]()
    var numOfRows: Int {
        if isSearching {
            return filteredNodes.count
        } else {
            return chats.count
        }
    }

    var searchController: UISearchController?
    var isSearching: Bool {
        if searchController?.active ?? false {
            return !(searchController?.searchBar.text?.isEmpty ?? true)
        }
        return false
    }

    var filteredNodes = [LeagueChat]()
    var activeNodes: [LeagueChat] {
        if isSearching {
            return filteredNodes
        } else {
            return chats
        }
    }

    func loadChats() {
        if let chatEntries = XMPPService.sharedInstance.chat().getLeagueChatEntries() {
            chats = chatEntries
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        navigationController?.hidesNavigationBarHairline = true
        setSearchController()
    }

    func setSearchController() {
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
    }


    override func viewWillAppear(animated: Bool) {
        // Load chats
        loadChats()

        // Add delegates
        XMPPService.sharedInstance.roster().addDelegate(self)
        XMPPService.sharedInstance.chat().addDelegate(self)

    }

    override func viewDidDisappear(animated: Bool) {
        // Remove delegates
        XMPPService.sharedInstance.roster().removeDelegate(self)
        XMPPService.sharedInstance.chat().removeDelegate(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segue.EnterChat {
            let chatTableController = segue.destinationViewController as! ChatViewController

            // Get the cell that generated this segue.
            if let selectedCell = sender as? RecentChatTableCell {
                let indexPath = tableView.indexPathForCell(selectedCell)!
                let selectedChat = activeNodes[indexPath.row]
                chatTableController.setInitialChatData(selectedChat)
                searchController?.active = false
            }
        }
    }
}

extension RecentChatViewController : UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController == self {
            if let mainTabBarController = tabBarController as? MainTabBarController {
                mainTabBarController.updateChatBadge(XMPPService.sharedInstance.chat())
            }
        }
    }
}

// MARK: Table view delegate

extension RecentChatViewController {

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numOfRows
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "RecentChatTableCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! RecentChatTableCell

        // Fetches the appropriate meal for the data source layout.
        let chat = activeNodes[indexPath.row]
        switch(chat.type) {
        case .Peer:
            let roster = XMPPService.sharedInstance.roster().getRosterByJID(chat.id)
            cell.setItem(chat, roster: roster)
            break

        case .Room:
            cell.setItem(chat, roster: nil)
        }

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
            // Delete the row from the data source
            chats.removeAtIndex(indexPath.row).remove()
            tableView.deleteRowsAtIndexPaths(
                [NSIndexPath(forRow: indexPath.row, inSection: 0)],
                withRowAnimation: .Fade)
        }
    }

}

extension RecentChatViewController : UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredNodes = chats.filter {
            if let keyword = searchController.searchBar.text {
                return $0.name.stringByReplacingOccurrencesOfString(" ", withString: "").localizedCaseInsensitiveContainsString(keyword)
            }
            return false
        }
        tableView.reloadData()
    }
}

extension RecentChatViewController : RosterDelegate, ChatDelegate {
    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster) {
        loadChats()
    }
    func didEnterChatRoom(sender: ChatService, from: LeagueChat) {
        loadChats()
    }
    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        loadChats()
    }
}