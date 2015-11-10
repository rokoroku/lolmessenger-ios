//
//  Weak.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 10..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}
