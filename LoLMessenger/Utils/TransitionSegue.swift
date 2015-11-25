//
//  TransitionSegue.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 23..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class TransitionSegue : UIStoryboardSegue {
    override func perform() {
        destinationViewController.transitioningDelegate = self
        sourceViewController.showViewController(destinationViewController, sender: sourceViewController)
    }
}

extension TransitionSegue : UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
        sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return TKFadeInAnimator(transitionDuration: 0.5, startingAlpha: 0.8)
    }
}