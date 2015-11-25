//
//  Weak.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 10..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Foundation

class Weak<T: AnyObject> : NSObject {

    var value : T? {
        get {
            self.schedule()
            return self.storedValue
        }
        set {
            self.storedValue = newValue
        }
    }
    private var storedValue : T?
    private var timer: NSTimer?
    private func schedule() {
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "invalidate:", userInfo: nil, repeats: false)
    }
    func invalidate(sender: AnyObject?) {
        timer?.invalidate()
        storedValue = nil
    }
    init (value: T) {
        super.init()
        self.value = value
        self.schedule()
    }
    deinit {
        invalidate(nil)
    }
}
