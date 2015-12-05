//
//  RecentChatViewController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 20..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup
import ChameleonFramework

class RecentChatViewController : UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBAction func addAction(sender: AnyObject) {
        DialogUtils.input(Localized("Enter New Chat"),
            message: Localized("Please enter the name of chat room you want to join"),
            placeholder: Localized("Room Name")) {
            if let name = $0, let chatEntry = XMPPService.sharedInstance.chat()?.joinRoom(name) {
                NavigationUtils.navigateToChat(chatId: chatEntry.id)
            }
        }
    }

    @IBAction func editAction(sender: AnyObject) {
        if (editing) {
            setEditing(false, animated: true)
            tableView.setEditing(false, animated: true)
            self.editButtonItem().title = Localized("Edit")
        } else {
            setEditing(true, animated: true)
            tableView.setEditing(true, animated: true)
            self.editButtonItem().title = Localized("Done")
        }
    }

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

    func reloadChats() {
        if let chatEntries = XMPPService.sharedInstance.chat()?.getLeagueChatEntries() {
            chats = chatEntries
        }
        let unreads = chats.reduce(0) { return $0 + $1.unread }
        if tabBarItem != nil {
            tabBarItem.badgeValue = unreads > 0 ? String(unreads) : nil
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.hidesNavigationBarHairline = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Theme.PrimaryColor
        setSearchController()

        let editButton = self.editButtonItem()
        editButton.title = Localized("Edit")
        editButton.action = Selector("editAction:")
        navigationItem.leftBarButtonItem = editButton
    }

    func updateLocale() {
        navigationItem.title = Localized("Chat")
        if tabBarItem != nil { tabBarItem.title = Localized("Chat") }
    }

    override func viewWillLayoutSubviews() {
        let adjustForTabbarInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.tableView!.contentInset = adjustForTabbarInsets;
        self.tableView!.scrollIndicatorInsets = adjustForTabbarInsets;
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
        // Load chats
        reloadChats()
        updateLocale()

        // Add delegates
        navigationController?.delegate = self
        XMPPService.sharedInstance.roster()?.addDelegate(self)
        XMPPService.sharedInstance.chat()?.addDelegate(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateLocale", name: LCLLanguageChangeNotification, object: nil)
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    override func viewWillDisappear(animated: Bool) {
        if editing {
            setEditing(false, animated: animated)
        }
        searchController?.active = false
    }

    override func viewDidDisappear(animated: Bool) {
        // Remove delegates
        if let _ = UIApplication.topViewController() as? STPopupContainerViewController {
            XMPPService.sharedInstance.chat()?.removeDelegate(self)
            XMPPService.sharedInstance.roster()?.removeDelegate(self)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: LCLLanguageChangeNotification, object: nil)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let chatViewController = segue.destinationViewController as? ChatViewController {
            // Get the cell that generated this segue.
            if let selectedCell = sender as? UITableViewCell {
                let indexPath = tableView.indexPathForCell(selectedCell)!
                let selectedChat = activeNodes[indexPath.row]
                chatViewController.setInitialChatData(selectedChat)
            }

            if segue.identifier == "EnterChat" {
                chatViewController.hideInputBox = false

            } else if segue.identifier == "PreviewChat" {
                chatViewController.hideInputBox = true
            }
        }
    }

}

extension RecentChatViewController : UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController == self.tabBarController {
            reloadChats()
        }
    }
}

// MARK: Table view delegate

extension RecentChatViewController : UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numOfRows
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // Fetches the appropriate chat for the data source layout.
        let chat = activeNodes[indexPath.row]
        switch(chat.type) {
        case .Peer:
            let cellIdentifier = "RecentChatTableCell"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! RecentChatTableCell

            let roster = XMPPService.sharedInstance.roster()?.getRosterByJID(chat.id)
            cell.setItem(chat, roster: roster)
            return cell

        case .Room:
            let cellIdentifier = "GroupChatTableCell"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! GroupChatTableCell

            let participants = XMPPService.sharedInstance.chat()?.getRoomByJID(chat.jid)?.getNumOfOccupants() ?? 0
            cell.setItem(chat, numParticipants: participants)
            return cell
        }
    }

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let leagueChat = chats.removeAtIndex(indexPath.row)
            if leagueChat.type == .Room {
                XMPPService.sharedInstance.chat()?.getRoomByJID(leagueChat.jid)?.leaveRoom()
            }
            leagueChat.remove()
            tableView.deleteRowsAtIndexPaths(
                [NSIndexPath(forRow: indexPath.row, inSection: 0)],
                withRowAnimation: .Fade)
        }
    }

}

extension RecentChatViewController : UISearchResultsUpdating, UISearchControllerDelegate {

    func didPresentSearchController(searchController: UISearchController) {
        if searchController.searchBar.superview?.isKindOfClass(UITableView) == false {
            //searchController.searchBar.removeFromSuperview()
            self.tableView.addSubview(searchController.searchBar)
        }
    }

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
        tableView.reloadData()
    }

    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        reloadChats()
    }
}