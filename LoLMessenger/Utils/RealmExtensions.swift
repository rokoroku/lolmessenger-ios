//
//  RealmExtensions.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 15..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import RealmSwift

extension Results {
    func toArray() -> [T] {
        return map { $0 }
    }
}

extension Realm {
    static let realmQueue = GCD.utilityQueue()
    static let sharedInstance = try! Realm()

    func retrieve<T: Object>(predicate: String? = nil, ofType: T.Type, callback: (Results<T>) -> Void) {
        var result = self.objects(T)
        if predicate != nil {
            result = result.filter(predicate!)
        }
        callback(result)
    }
}

extension Object {

    func remove() {
        if let realm = self.realm {
            do {
                try realm.write {
                    realm.delete(self)
                }
            } catch _ {

            }
        }
    }

    func update(block: dispatch_block_t) {
        if let realm = realm {
            do {
                try realm.write(block)
            } catch _ {

            }
        } else {
            block()
        }
    }
}
