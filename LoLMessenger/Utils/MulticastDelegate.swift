//
//  MulticastDelegate.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 7..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Foundation

class MulticastDelegateNode <T:AnyObject> {
    weak var delegate : T?
    
    init(object: T){
        self.delegate = object;
    }
}

class MulticastDelegate<T: AnyObject> {

    typealias DelegateType = T
    var delegates = [MulticastDelegateNode<DelegateType>]()
    
    func addDelegate(element: DelegateType) {
        var contain = false;
        for item in delegates {
            if item.delegate === element {
                contain = true;
            }
        }
        if !contain {
            delegates.append(MulticastDelegateNode<DelegateType>(object: element))
        }
    }
    
    func removeDelegate(element: DelegateType) {
        for var i=0; i < delegates.count; i++ {
            let item = delegates[i]
            if item.delegate === element {
                delegates.removeAtIndex(i--)
            }
        }
    }
    
    func invoke(invocation: (T) -> ()) {
        for var i=0; i < delegates.count; i++ {
            let node = delegates[i]
            if let delegate = node.delegate {
                invocation(delegate)
            } else {
                delegates.removeAtIndex(i--)
            }
        }
    }
}