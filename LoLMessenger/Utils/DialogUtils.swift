//
//  DialogUtils.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 19..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit

class DialogUtils {
    class func alert(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {

        var actions = [UIAlertAction]()
        if handler != nil {
            actions.append(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        }
        actions.append(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: handler))

        DialogUtils.alert(title,
            message: message,
            actions: actions)
    }

    class func input(title: String, message: String, placeholder: String? = nil, callback: ((String?) -> Void)) {
        let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: UIAlertControllerStyle.Alert)

        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = placeholder
            textField.textColor = Theme.TextColorBlack
        }
        alert.addAction(
            UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(
            UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { _ in
                callback(alert.textFields?[0].text)
            }))
        UIApplication.topViewController()?.presentViewController(alert, animated: true, completion: nil)

    }

    class func alert(title: String, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)

        actions.forEach {
            alert.addAction($0)
        }

        UIApplication.topViewController()?.presentViewController(alert, animated: true, completion: nil)
    }
}