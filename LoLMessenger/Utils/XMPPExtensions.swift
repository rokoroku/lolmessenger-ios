//
//  XMPPExtensions.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 2..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import UIKit
import Foundation
import XMPPFramework

extension XMPPPresence {
    enum Show {
        case Chat
        case Away
        case Dnd
        case Unavailable

        func icon() -> UIImage? {
            switch(self) {
            case .Chat: return UIImage(named: "icon_green")
            case .Dnd: return UIImage(named: "icon_yellow")
            case .Away: return UIImage(named: "icon_red")
            default: return UIImage(named: "icon_black")
            }
        }
    }

    func showType() -> Show {
        if let value = getElementStringValue("show") {
            switch value {
            case "chat": return .Chat
            case "away": return .Away
            case "dnd": return .Dnd
            default: return .Unavailable
            }
        }
        return .Unavailable
    }
}

extension DDXMLElement {
    func getElementStringValue(elementName: String, defaultValue: String? = nil) -> String? {
        if let element = elementForName(elementName) {
            return element.stringValue()
        } else if let _ = defaultValue {
            return defaultValue!
        } else {
            return nil
        }
    }

    func getElementIntValue(elementName: String, defaultValue: Int? = nil) -> Int? {
        if let element = elementForName(elementName) {
            return element.stringValueAsNSInteger()
        } else if let _ = defaultValue {
            return defaultValue!
        } else {
            return nil
        }
    }
}
