//
//  ChatViewController.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 21..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import XMPPFramework
import ChameleonFramework

struct ChatData {
    var size: Int
    var offset: Int
    var messages: [LeagueMessage.RawData]

    init(chat: LeagueChat) {
        size = chat.messages.count
        offset = size - ChatViewController.windowSize
        if offset < 0 { offset = 0 }

        messages = [] as [LeagueMessage.RawData]
        for i in offset..<size {
            messages.append(chat.messages[i].raw())
        }
    }

    mutating func append(message: LeagueMessage.RawData) {
        messages.append(message)
        size++
    }

    mutating func loadMore(chat: LeagueChat) -> Int {
        if offset > 0 {
            let from = offset
            offset -= ChatViewController.windowSize
            if offset < 0 { offset = 0 }

            var loadedMessages = [] as [LeagueMessage.RawData]
            for i in offset..<from {
                loadedMessages.append(chat.messages[i].raw())
            }
            messages.insertContentsOf(loadedMessages, at: 0)
            return loadedMessages.count
        }
        return 0
    }
}

class ChatViewController : UIViewController {

    static let windowSize = 50

    // This constraint ties an element at zero points from the bottom layout guide
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBox: UIView!

    var chatJID: XMPPJID?
    var chatName: String?
    var chatData: ChatData?
    var hideInputBox: Bool = false

    var numOfRows: Int {
        return chatData?.messages.count ?? 0
    }

    var isFetching = false

    func setInitialChatData(chat: LeagueChat) {
        chatJID = chat.jid
        chatName = chat.name
        chatData = ChatData(chat: chat)
    }

    func reloadChats() {
        if let chatId = self.chatJID, let chat = XMPPService.sharedInstance.chat().getLeagueChatEntryByJID(chatId) {
            setInitialChatData(chat)
            tableView.reloadData()
        }
    }

    override func awakeFromNib() {
        if #available(iOS 9.0, *) {
            UILabel.appearanceWhenContainedInInstancesOfClasses([UITextField.self]).textColor = Theme.TextColorDisabled
        }
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        tableView.reloadData()
        let rect = CGRectMake(0,
            tableView.contentSize.height - tableView.bounds.size.height,
            tableView.bounds.size.width,
            tableView.bounds.size.height)
        tableView.scrollRectToVisible(rect, animated: false)
        scrollToBottom()

        textField.delegate = self
        textField.backgroundColor = UIColor.whiteColor()
        textField.superview?.backgroundColor = Theme.SecondaryColor
        textField.textColor = Theme.TextColorBlack

        sendButton.addTarget(self, action: "sendMessage", forControlEvents: UIControlEvents.TouchUpInside)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))

        if let title = chatName {
            navigationItem.title = title
        }
        //navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Alarm", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
    }

    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "adjustKeyboardHeight:",
            name: UIKeyboardWillChangeFrameNotification,
            object: nil)
        if let chatJID = self.chatJID {
            updateTitle(XMPPService.sharedInstance.roster().getRosterByJID(chatJID))
        }
    }

    override func viewWillAppear(animated: Bool) {
        XMPPService.sharedInstance.roster().addDelegate(self)
        XMPPService.sharedInstance.chat().addDelegate(self)
    }

    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if let jid = chatJID, let chat = XMPPService.sharedInstance.chat().getLeagueChatEntryByJID(jid) {
            chat.update {
                chat.clearUnread()
            }
            XMPPService.sharedInstance.updateBadge()
        }
    }

    override func viewDidDisappear(animated: Bool) {
        XMPPService.sharedInstance.chat().removeDelegate(self)
        XMPPService.sharedInstance.roster().removeDelegate(self)

        if #available(iOS 9.0, *) {
            UILabel.appearanceWhenContainedInInstancesOfClasses([UILabel.self]).textColor = Theme.TextColorPrimary
        }
    }

    override func viewWillLayoutSubviews() {
        let adjustForTabbarInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0)
        self.inputBox.hidden = hideInputBox
        self.tableView!.contentInset = adjustForTabbarInsets;
        self.tableView!.scrollIndicatorInsets = adjustForTabbarInsets;
    }

    func scrollToBottom(animate:Bool = false) {
        Async.main(after: 0.01) {
            if self.numOfRows > 0 {
                let lastPath = NSIndexPath(forRow: self.numOfRows-1, inSection: 0)
                self.tableView.scrollToRowAtIndexPath(lastPath, atScrollPosition: .Top, animated: animate)
            }
        }
    }

    func adjustKeyboardHeight(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            let beginFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue()
            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)

            var height = endFrame?.size.height ?? 0
            if endFrame?.size.height > 0 {
                if beginFrame?.origin.y < endFrame?.origin.y {
                    height = 0
                }
            }

            let offset = self.tableView.contentOffset
            if height > 0 && tableView.contentSize.height - height > tableView.bounds.size.height {
                tableView.setContentOffset(CGPointMake(0, offset.y + height), animated: false)
            }

            self.keyboardHeightLayoutConstraint?.constant = height

            UIView.animateWithDuration(duration,
                delay: NSTimeInterval(0),
                options: animationCurve,
                animations: { self.view.layoutIfNeeded() },
                completion: { _ in
                    if height > 0 {
                        if let lastCell = self.tableView.indexPathsForVisibleRows?.last {
                            self.tableView.scrollToRowAtIndexPath(lastCell, atScrollPosition: .Bottom, animated: false)
                        }
                    }
                })

        }
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func sendMessage() {
        if let jid = chatJID, let body = textField.text {
            if !body.isEmpty() {
                textField.text = nil
                XMPPService.sharedInstance.chat().sendMessage(jid, msg: body)
            }
        }
    }


    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        print(sender)
        // Get the cell that generated the segue.
        if let cell = sender as? ChatTableCell, let roster = cell.roster {

            if let chatViewController = segue.destinationViewController as? ChatViewController,
                let chat = XMPPService.sharedInstance.chat().getLeagueChatEntryByJID(roster.jid()) {
                    chatViewController.setInitialChatData(chat)
            }

            else if let summonerViewController = segue.destinationViewController as? SummonerDialogViewController {
                summonerViewController.roster = roster
            }
        }
    }

}

// MARK: - Table View Delegates

extension ChatViewController : UITableViewDelegate, UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numOfRows
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // Fetches the appropriate message for the data source layout.
        if indexPath.row >= chatData?.messages.count {
            return UITableViewCell()
        }

        let message = (chatData?.messages[indexPath.row])!
        if message.isMine {
            let cellIdentifier = "BalloonMine"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ChatTableCell
            let roster = XMPPService.sharedInstance.myRosterElement
            cell.setItem(roster, message: message)
            return cell

        } else {
            let cellIdentifier = "BalloonOthers"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ChatTableCell
            let roster = XMPPService.sharedInstance.roster().getRosterByJID(chatJID!)
            cell.setItem(roster, message: message)
            return cell
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if tableView.contentOffset.y <= -100 && chatJID != nil && !isFetching {
            if let chat = XMPPService.sharedInstance.chat().getLeagueChatEntryByJID(chatJID!) {
                self.isFetching = true
                let loadedRows = chatData?.loadMore(chat)
                if loadedRows > 0 {
                    var previousContentOffset = tableView.contentOffset
                    let previousContentHeight = tableView.contentSize.height
                    let previousVisibleRow: NSIndexPath? = tableView.indexPathsForVisibleRows?.first

                    tableView.reloadData()
                    tableView.panGestureRecognizer.enabled = false
                    tableView.setContentOffset(CGPointMake(0, previousContentOffset.y + tableView.contentSize.height - previousContentHeight), animated: false)

                    Async.main(after: 0.01) {
                        self.tableView.panGestureRecognizer.enabled = true
                        previousContentOffset.y += self.tableView.contentSize.height - previousContentHeight
                        self.tableView.setContentOffset(previousContentOffset, animated: false)

                        if let previousRow = previousVisibleRow?.row {
                            let pathToRestore = NSIndexPath(forRow: previousRow + loadedRows!, inSection: 0)
                            self.tableView.scrollToRowAtIndexPath(pathToRestore, atScrollPosition: .Top, animated: true)
                        }
                    }

                    Async.main(after: 0.25) {
                        self.tableView.panGestureRecognizer.enabled = true
                    }
                }
                Async.background(after: 2) {
                    self.isFetching = false
                }
            }
        }
    }
}

extension ChatViewController : UITextFieldDelegate {

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard.
        sendMessage()
        return true
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        checkValidMessage()
        return true
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        // Disable the send button while editing.
        sendButton.enabled = false
    }

    func textFieldDidEndEditing(textField: UITextField) {
        checkValidMessage()
    }


    func checkValidMessage() {
        // Disable the send button if the text field is empty.
        let text = textField.text ?? ""
        sendButton.enabled = !text.isEmpty()
    }

}

extension ChatViewController : RosterDelegate, ChatDelegate {

    func updateTitle(roster: LeagueRoster?) {

        let titleLabel = IconLabel()
        titleLabel.imageSize = CGSizeMake(14, 14)
        titleLabel.image = roster?.getStatusIcon() ?? PresenceShow.Unavailable.icon()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        titleLabel.text = roster?.username ?? chatName
        titleLabel.font = UIFont.boldSystemFontOfSize(16.0)
        if roster?.available ?? false {
            titleLabel.textColor = Theme.TextColorPrimary
        } else {
            titleLabel.textColor = Theme.TextColorDisabled
        }

        let tempLabel = UILabel(frame: navigationController?.navigationBar.frame ?? CGRect.zero)
        tempLabel.numberOfLines = 0
        tempLabel.textAlignment = .Center
        tempLabel.text = titleLabel.text
        tempLabel.font = UIFont.boldSystemFontOfSize(16.0)
        tempLabel.sizeToFit()

        titleLabel.frame =  CGRectMake(0, 0, tempLabel.frame.width + 20, tempLabel.frame.height)

        navigationItem.titleView = titleLabel
    }

    func didReceiveRosterUpdate(sender: RosterService, from: LeagueRoster) {
        if from.jid().isEqualToJID(chatJID, options: XMPPJIDCompareUser) {
            updateTitle(from)
        }
    }

    func didReceiveNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        if from.jid.isEqualToJID(chatJID, options: XMPPJIDCompareUser) {
            insertMessage(message)
        }
    }

    func didSendNewMessage(sender: ChatService, from: LeagueChat, message: LeagueMessage.RawData) {
        if from.jid.isEqualToJID(chatJID, options: XMPPJIDCompareUser) {
            insertMessage(message)
        }
    }

    func insertMessage(message: LeagueMessage.RawData) {
        chatData?.append(message)
        tableView.reloadData()
        scrollToBottom(true)
    }
}