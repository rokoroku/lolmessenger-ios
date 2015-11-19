//
//  StoredProperties.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 10. 25..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Foundation
import XMPPFramework

class StoredProperties {
    class Settings {
        static let notifyMessage = StoredBoolProperty(key: "notifyMessage", defaultValue: true)
        static let notifySubscription = StoredBoolProperty(key: "notifySubscription", defaultValue: true)
        static let notifyWithSound = StoredBoolProperty(key: "notifyWithSound", defaultValue: true)
        static let notifyWithVibrate = StoredBoolProperty(key: "notifyWithVibrate", defaultValue: true)
        static let notifyBackgroundExpire = StoredBoolProperty(key: "notifyBackgroundExpiration", defaultValue: true)
        static let backgroundEnabled: Bool = {
            if let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist"),
                dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
                backgroundModes = dict["UIBackgroundModes"] as? [String] {
                    return backgroundModes.contains("voip") ?? false
            }
            return false
        }()
    }

    class AlarmDisabledJIDs {
        class func set(userid: String, disable: Bool) {
            if disable {
                NSUserDefaults.standardUserDefaults().setBool(disable, forKey: Constants.Key.Alarm(userid))
            } else {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.Key.Alarm(userid))
            }
            NSUserDefaults.standardUserDefaults().synchronize()
        }

        class func contains(userid: String) -> Bool {
            let key = Constants.Key.Alarm(userid)
            if let _ = NSUserDefaults.standardUserDefaults().objectForKey(key) {
                return NSUserDefaults.standardUserDefaults().boolForKey(key)
            } else {
                return false
            }
        }
    }

    class Presences {
        class func put(userid: String, presence: XMPPPresence) {
            NSUserDefaults.standardUserDefaults().setObject(
                NSKeyedArchiver.archivedDataWithRootObject(presence), forKey: Constants.Key.Presence(userid)
            )
            NSUserDefaults.standardUserDefaults().synchronize()
        }

        class func get(userid: String) -> XMPPPresence? {
            if let storedData = NSUserDefaults.standardUserDefaults().objectForKey(Constants.Key.Presence(userid)) as? NSData,
                let storedPresence = NSKeyedUnarchiver.unarchiveObjectWithData(storedData) as? XMPPPresence {
                return storedPresence
            }
            return nil
        }
    }
}

class StoredBoolProperty {
    var key: String
    var value: Bool {
        get {
            return storedValue
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: key)
            self.storedValue = newValue
        }
    }
    private var storedValue: Bool

    init(key: String, defaultValue: Bool) {
        self.key = key
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(key) {
            self.storedValue = NSUserDefaults.standardUserDefaults().boolForKey(key)
        } else {
            self.storedValue = defaultValue
        }
    }
}


class StoredProperty {
    var key: String
    var value: String? {
        get {
            return storedValue
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: key)
            NSUserDefaults.standardUserDefaults().synchronize()
            self.storedValue = newValue
        }
    }
    private var storedValue: String?

    init(key: String, defaultValue: String? = nil) {
        self.key = key
        if let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String {
            self.storedValue = value
        } else {
            self.storedValue = defaultValue
        }
    }
}