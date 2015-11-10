//
//  UIViewExtensions.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 4..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import STPopup

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