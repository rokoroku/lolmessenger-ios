//
//  TKTransitionSubmitButton
//
//  Created by Takuya Okamoto on 2015/08/07.
//  Copyright (c) 2015年 Uniface. All rights reserved.
//

import Foundation
import UIKit

let PINK = UIColor(red:0.992157, green: 0.215686, blue: 0.403922, alpha: 1)
let DARK_PINK = UIColor(red:0.798012, green: 0.171076, blue: 0.321758, alpha: 1)

@IBDesignable
public class TKTransitionSubmitButton : UIButton, UIViewControllerTransitioningDelegate {

    public var didEndFinishAnimation : (()->())? = nil

    let springGoEase = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
    let shrinkCurve = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    let expandCurve = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    let shrinkDuration: CFTimeInterval  = 0.1

    lazy var spiner: SpinerLayer! = {
        let s = SpinerLayer(frame: self.frame)
        self.layer.addSublayer(s)
        return s
    }()

    @IBInspectable public var highlightedBackgroundColor: UIColor? = DARK_PINK {
        didSet {
            self.setBackgroundColor()
        }
    }
    @IBInspectable public var normalBackgroundColor: UIColor? = PINK {
        didSet {
            self.setBackgroundColor()
        }
    }

    var cachedTitle: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    override public var highlighted: Bool {
        didSet {
            self.setBackgroundColor()
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup() {
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        self.setBackgroundColor()
    }

    func setBackgroundColor() {
        if (highlighted) {
            self.backgroundColor = highlightedBackgroundColor
        }
        else {
            self.backgroundColor = normalBackgroundColor
        }
    }

    public func startLoadingAnimation() {
        self.cachedTitle = titleForState(.Normal)
        self.setTitle("", forState: .Normal)
        self.shrink()
        NSTimer.schedule(delay: shrinkDuration - 0.25) { timer in
            self.spiner.animation()
        }
    }

    public func stopLoadingAnimation() {
        self.spiner.stopAnimation()
        self.restore()
        NSTimer.schedule(delay: shrinkDuration - 0.25) { timer in
            self.returnToOriginalState()
        }
    }

    public func startFinishAnimation(delay: NSTimeInterval, completion:(()->())?) {
        NSTimer.schedule(delay: delay) { timer in
            self.didEndFinishAnimation = completion
            self.expand()
            self.spiner.stopAnimation()
        }
    }

    public func animate(duration: NSTimeInterval, completion:(()->())?) {
        startLoadingAnimation()
        startFinishAnimation(duration, completion: completion)
    }

    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        let a = anim as! CABasicAnimation
        if a.keyPath == "transform.scale" {
            didEndFinishAnimation?()
            NSTimer.schedule(delay: 1) { timer in
                self.returnToOriginalState()
            }
        }
    }

    func returnToOriginalState() {
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, forState: .Normal)
    }

    func shrink() {
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = frame.width
        shrinkAnim.toValue = frame.height
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
        shrinkAnim.fillMode = kCAFillModeForwards
        shrinkAnim.removedOnCompletion = false
        layer.addAnimation(shrinkAnim, forKey: shrinkAnim.keyPath)
    }

    func restore() {
        let restoreAnim = CABasicAnimation(keyPath: "bounds.size.width")
        restoreAnim.fromValue = frame.height
        restoreAnim.toValue = frame.width
        restoreAnim.duration = shrinkDuration
        restoreAnim.timingFunction = shrinkCurve
        restoreAnim.fillMode = kCAFillModeForwards
        restoreAnim.removedOnCompletion = false
        layer.addAnimation(restoreAnim, forKey: restoreAnim.keyPath)
    }

    func expand() {
        let expandAnim = CABasicAnimation(keyPath: "transform.scale")
        expandAnim.fromValue = 1.0
        expandAnim.toValue = 26.0
        expandAnim.timingFunction = expandCurve
        expandAnim.duration = 0.5
        expandAnim.delegate = self
        expandAnim.fillMode = kCAFillModeForwards
        expandAnim.removedOnCompletion = false
        layer.addAnimation(expandAnim, forKey: expandAnim.keyPath)
    }
    
}


class SpinerLayer :CAShapeLayer {

    init(frame:CGRect) {
        super.init()

        let radius:CGFloat = (frame.height / 2) * 0.5
        self.frame = CGRectMake(0, 0, frame.height, frame.height)
        let center = CGPointMake(frame.height / 2, bounds.center.y)
        let startAngle = 0 - M_PI_2
        let endAngle = M_PI * 2 - M_PI_2
        let clockwise: Bool = true
        self.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: clockwise).CGPath

        self.fillColor = nil
        self.strokeColor = UIColor.whiteColor().CGColor
        self.lineWidth = 1

        self.strokeEnd = 0.4
        self.hidden = true
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animation() {
        self.hidden = false
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = 0
        rotate.toValue = M_PI * 2
        rotate.duration = 0.4
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        rotate.repeatCount = HUGE
        rotate.fillMode = kCAFillModeForwards
        rotate.removedOnCompletion = false
        self.addAnimation(rotate, forKey: rotate.keyPath)

    }

    func stopAnimation() {
        self.hidden = true
        self.removeAllAnimations()
    }
}


public class TKFadeInAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var transitionDuration: NSTimeInterval = 0.5
    var startingAlpha: CGFloat = 0.0

    public convenience init(transitionDuration: NSTimeInterval, startingAlpha: CGFloat){
        self.init()
        self.transitionDuration = transitionDuration
        self.startingAlpha = startingAlpha
    }

    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return transitionDuration
    }

    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()!

        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!

        toView.alpha = startingAlpha
        fromView.alpha = 0.8

        /*
        var frame = toView.frame
        if (frame.y > 0)
        {
            // In my experience, the final frame is always a zero rect, so this is always hit
            var insets = UIEdgeInsetsZero;
            // My "solution" was to inset the container frame by the difference between the
            // actual status bar height and the normal status bar height
            insets.top = UIApplication.sharedApplication().statusBarFrame.height - 20;
            frame = UIEdgeInsetsInsetRect(containerView.bounds, insets)
        }
        toView.frame = frame
        */
        containerView.addSubview(toView)

        UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in

            toView.alpha = 1.0
            fromView.alpha = 0.0

            }, completion: {
                _ in
                fromView.alpha = 1.0
                transitionContext.completeTransition(true)
        })
    }
}

