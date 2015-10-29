//
//  YUTableView.swift
//  YUTableView-Swift
//
//  Created by yücel uzun on 22/07/15.
//  Copyright © 2015 Yücel Uzun. All rights reserved.
//

import UIKit

protocol YUTableViewDelegate {
    /**  Called inside "cellForRowAtIndexPath:" method. Edit your cell in this funciton. */
    func setContentsOfCell (cell: UITableViewCell, node: YUTableViewNode);
    /** Uses the returned value as cell height if implemented */
    func heightForIndexPath (indexPath: NSIndexPath) -> CGFloat?;
    /** Uses the returned value as cell height if heightForIndexPath is not implemented */
    func heightForNode (node: YUTableViewNode) -> CGFloat?;
    /** Called whenever a node is selected. You should check if it's a leaf. */
    func didSelectNode (node: YUTableViewNode, indexPath: NSIndexPath);
}

extension YUTableViewDelegate {
    func heightForNode (node: YUTableViewNode) -> CGFloat? { return nil; };
    func heightForIndexPath (indexPath: NSIndexPath) -> CGFloat? { return nil; };
    func didSelectNode (node: YUTableViewNode, indexPath: NSIndexPath) {}
}

class YUTableView: UITableView
{
    private var yuTableViewDelegate : YUTableViewDelegate!;
    private var firstLevelNodes: [YUTableViewNode]!;
    private var rootNode : YUTableViewNode!;
    private var nodesToDisplay: [YUTableViewNode]!;
    private var activeNodesId: [Int]!;

    /** If "YUTableViewNode"s don't have individual identifiers, this one is used */
    var defaultCellIdentifier: String!;

    var insertRowAnimation: UITableViewRowAnimation = .Right;
    var deleteRowAnimation: UITableViewRowAnimation = .Left;
    var animationCompetitionHandler: () -> Void = {};
    /** Removes other open items before opening a new one */
    var allowOnlyOneActiveNodeInSameLevel: Bool = false;
    var expandAllNodeAtFirstTime: Bool = false;
    var isFirstLoaded: Bool = true;
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        initializeDefaultValues ();
    }
    
    required override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style);
        initializeDefaultValues ();
    }
    
    private func initializeDefaultValues () {
        self.delegate = self;
        self.dataSource = self;
    }
    
    func setDelegate (delegate: YUTableViewDelegate) {
        yuTableViewDelegate = delegate;
    }

    func isActiveNode (node: YUTableViewNode) -> Bool {
        if activeNodesId == nil { activeNodesId = [] }
        return activeNodesId.contains(node.nodeId)
    }

    func setNodes (nodes: [YUTableViewNode]) {
        rootNode = YUTableViewNode(childNodes: nodes);
        self.firstLevelNodes = nodes;
        if activeNodesId == nil { activeNodesId = [] }
        if expandAllNodeAtFirstTime && isFirstLoaded {
            self.nodesToDisplay = []
            for firstLevelNode in nodes {
                nodesToDisplay.append(firstLevelNode)
                if firstLevelNode.childNodes != nil {
                    firstLevelNode.isActive = true;
                    activeNodesId.append(firstLevelNode.nodeId)
                    for nextLevelNode in firstLevelNode.childNodes {
                        nodesToDisplay.append(nextLevelNode)
                    }
                }
            }
        } else {
            self.nodesToDisplay = []
            for firstLevelNode in nodes {
                nodesToDisplay.append(firstLevelNode)
                if firstLevelNode.childNodes != nil && isActiveNode(firstLevelNode) {
                    firstLevelNode.isActive = true;
                    for nextLevelNode in firstLevelNode.childNodes {
                        nodesToDisplay.append(nextLevelNode)
                    }
                }
            }
        }
        if !nodesToDisplay.isEmpty {
            self.isFirstLoaded = false
        }
        reloadData();
    }
    
    func selectNodeAtIndex (index: Int) {
        let node = nodesToDisplay [index];
        openNodeAtIndexRow(index);
        yuTableViewDelegate?.didSelectNode(node, indexPath: NSIndexPath(forRow: index, inSection: 0));
    }
    
    func selectNode (node: YUTableViewNode) {
        var index = nodesToDisplay.indexOf(node);
        if index == nil {
            selectNode(node.getParent()!);
            index = nodesToDisplay.indexOf(node);
        }
        openNodeAtIndexRow(index!);
        yuTableViewDelegate?.didSelectNode(node, indexPath: NSIndexPath(forRow: index!, inSection: 0));
    }
}

extension YUTableView: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nodesToDisplay != nil {
            return nodesToDisplay.count;
        }
        return 0;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let node = nodesToDisplay[indexPath.row];
        let cellIdentifier = node.cellIdentifier != nil ? node.cellIdentifier : defaultCellIdentifier;
        let cell = self.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath);
        yuTableViewDelegate?.setContentsOfCell(cell, node: node);
        return cell;
    }
}

extension YUTableView: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = yuTableViewDelegate?.heightForIndexPath(indexPath)  {
            return height;
        }
        if let height = yuTableViewDelegate?.heightForNode(nodesToDisplay[indexPath.row]) {
            return height;
        }
        return tableView.rowHeight;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodesToDisplay [indexPath.row];
        yuTableViewDelegate.didSelectNode(node, indexPath: indexPath);
        if node.isActive {
            closeNodeAtIndexRow(indexPath.row);
        } else if node.hasChildren() {
            openNodeAtIndexRow(indexPath.row);
        }
    }
}

private extension YUTableView {

    func openNodeAtIndexRow (var indexRow: Int) {
        let node = nodesToDisplay [indexRow];
        if !isActiveNode(node) {
            activeNodesId.append(node.nodeId)
        }

        if allowOnlyOneActiveNodeInSameLevel {
            closeNodeAtSameLevelWithNode(node, indexRow: indexRow);
            indexRow = nodesToDisplay.indexOf(node)!;
        }
        if let newNodes = node.childNodes {
            nodesToDisplay.insert(newNodes, atIndex: indexRow + 1);
            let indexesToInsert = indexesFromRow(indexRow + 1, count: newNodes.count)!;
            updateTableRows(insertRows: indexesToInsert, removeRows: nil);
            node.isActive = true;
        }
    }

    func closeNodeAtSameLevelWithNode (node: YUTableViewNode, indexRow: Int) {
        if let siblings = node.getParent()?.childNodes {
            if let activeNode = siblings.filter( { $0.isActive }).first {
                closeNodeAtIndexRow (nodesToDisplay.indexOf(activeNode)!);
            }
        }
    }
    
    func closeNodeAtIndexRow (indexRow: Int, shouldReloadClosedRow: Bool = false ) {
        let node = nodesToDisplay [indexRow];
        if isActiveNode(node) {
            if let index = activeNodesId.indexOf(node.nodeId) {
                activeNodesId.removeAtIndex(index)
            }
        }
        let numberOfDisplayedChildren = getNumberOfDisplayedChildrenAndDeactivateEveryNode(node);
        nodesToDisplay.removeRange(indexRow + 1...indexRow+numberOfDisplayedChildren );
        updateTableRows(removeRows: indexesFromRow(indexRow + 1, count: numberOfDisplayedChildren));
        node.isActive = false;
        if shouldReloadClosedRow {
            self.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexRow, inSection: 0)], withRowAnimation: .Fade)
        }
    }
    
    func getNumberOfDisplayedChildrenAndDeactivateEveryNode (node: YUTableViewNode) -> Int {
        var count = 0;
        if let children = node.childNodes {
            count += children.count;
            for node in children.filter ({$0.isActive })  {
                count += getNumberOfDisplayedChildrenAndDeactivateEveryNode(node);
                node.isActive = false;
            }
        }
        return count;
    }
    
    func indexesFromRow (from: Int, count: Int) -> [NSIndexPath]? {
        var indexes = [NSIndexPath] ();
        for var i = 0; i < count; i++ {
            indexes.append(NSIndexPath(forRow: i + from, inSection: 0));
        }
        if (indexes.count == 0) { return nil; }
        return indexes;
    }

    func updateTableRows ( insertRows indexesToInsert: [NSIndexPath]? = nil, removeRows indexesToRemove: [NSIndexPath]? = nil) {
        CATransaction.begin();
        CATransaction.setCompletionBlock { () -> Void in
            self.animationCompetitionHandler ();
        };
        self.beginUpdates();
        if indexesToRemove != nil && indexesToRemove?.count > 0 {
            self.deleteRowsAtIndexPaths(indexesToRemove!, withRowAnimation: self.deleteRowAnimation);
        }
        if indexesToInsert != nil && indexesToInsert?.count > 0 {
            self.insertRowsAtIndexPaths(indexesToInsert!, withRowAnimation: self.insertRowAnimation);
        }
        self.endUpdates();
        CATransaction.commit();
    }
    
}

private extension Array {
    mutating func insert (items: [Element], atIndex: Int) {
        var counter = 0;
        for item in items {
            insert(item, atIndex: atIndex + counter);
            counter++;
        }
    }
}