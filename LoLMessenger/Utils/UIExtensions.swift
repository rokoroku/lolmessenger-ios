//
//  UIViewExtensions.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 4..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

extension UIViewController {
    func isVisible() -> Bool {
        return isViewLoaded() && view.window != nil
    }
}

extension UIView {
    func rotate180Degrees(duration: CFTimeInterval = 0.2) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")

        if let previousAniamation = self.layer.animationForKey("rotation") as? CABasicAnimation,
            let prevRotation = previousAniamation.toValue as? CGFloat
        {
            rotateAnimation.fromValue = prevRotation
            rotateAnimation.toValue = prevRotation + CGFloat(M_PI * 1.0)

        } else {
            rotateAnimation.fromValue = 0
            rotateAnimation.toValue = CGFloat(M_PI * 1.0)
        }

        rotateAnimation.duration = duration
        rotateAnimation.fillMode = kCAFillModeBoth
        rotateAnimation.removedOnCompletion = false

        self.layer.addAnimation(rotateAnimation, forKey: "rotation")
    }
}

extension UIImageView {
    func crossfade(image: UIImage) {
        UIView.transitionWithView(self,
            duration:0.5,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: { self.image = image },
            completion: nil)
    }
}

extension UIImage {

    func tint(color: UIColor, blendMode: CGBlendMode) -> UIImage {
        let drawRect = CGRectMake(0.0, 0.0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextClipToMask(context, drawRect, CGImage)
        color.setFill()
        UIRectFill(drawRect)
        drawInRect(drawRect, blendMode: blendMode, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
}

extension CGRect {
    var x: CGFloat {
        get {
            return self.origin.x
        }
        set {
            self = CGRectMake(newValue, self.minY, self.width, self.height)
        }
    }

    var y: CGFloat {
        get {
            return self.origin.y
        }
        set {
            self = CGRectMake(self.x, newValue, self.width, self.height)
        }
    }

    var width: CGFloat {
        get {
            return self.size.width
        }
        set {
            self = CGRectMake(self.x, self.width, newValue, self.height)
        }
    }

    var height: CGFloat {
        get {
            return self.size.height
        }
        set {
            self = CGRectMake(self.x, self.minY, self.width, newValue)
        }
    }


    var top: CGFloat {
        get {
            return self.origin.y
        }
        set {
            y = newValue
        }
    }

    var bottom: CGFloat {
        get {
            return self.origin.y + self.size.height
        }
        set {
            self = CGRectMake(x, newValue - height, width, height)
        }
    }

    var left: CGFloat {
        get {
            return self.origin.x
        }
        set {
            self.x = newValue
        }
    }

    var right: CGFloat {
        get {
            return x + width
        }
        set {
            self = CGRectMake(newValue - width, y, width, height)
        }
    }


    var midX: CGFloat {
        get {
            return self.x + self.width / 2
        }
        set {
            self = CGRectMake(newValue - width / 2, y, width, height)
        }
    }

    var midY: CGFloat {
        get {
            return self.y + self.height / 2
        }
        set {
            self = CGRectMake(x, newValue - height / 2, width, height)
        }
    }


    var center: CGPoint {
        get {
            return CGPointMake(self.midX, self.midY)
        }
        set {
            self = CGRectMake(newValue.x - width / 2, newValue.y - height / 2, width, height)
        }
    }
}