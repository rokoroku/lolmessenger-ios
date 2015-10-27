//
//  IconLabel.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 27..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class IconLabel: UILabel {
    var imageView: UIImageView?
    var image: UIImage? {
        didSet {
            repositionImage()
        }
    }

    var textBody: String? {
        didSet {
            super.text = text
            repositionImage()
        }
    }
    var imageSize: CGSize?

    func repositionImage() {
        if let imageView = imageView {
            let size = imageSize ?? CGSizeMake(frame.size.height, frame.size.height)
            imageView.image = self.image
            imageView.frame = CGRectMake(0, 2, size.width, size.height)

        } else {
            imageView = UIImageView()
            addSubview(self.imageView!)
            repositionImage()
        }
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        repositionImage()
    }

    override func drawTextInRect(rect: CGRect) {
        // Leave some space to draw the image.
        let size = imageSize ?? CGSizeMake(frame.size.height, frame.size.height)
        let insets = UIEdgeInsets(top: 0, left: size.width + 4 ?? 0, bottom: 0, right: 0)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}
