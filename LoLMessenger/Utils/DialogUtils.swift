//
//  DialogUtils.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 19..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class DialogUtils {
    class func alert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(
            UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        
        UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
    }
}