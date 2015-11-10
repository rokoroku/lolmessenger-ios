//
//  RealmExtensions.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 15..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import RealmSwift

typealias realm_dispatch_block = ((realm: Realm) -> Void)

class DedicatedRealm {
    // Create a separate thread (with a serial dispatch queue) for Realm writes
    // From Realm docs: "Please note that writes block each other, and will block the thread they are made on if other writes are in progress. This is similar to any other persistence solution, so we do recommend that you use the usual best-practices for that situation, namely offloading your writes to a separate thread"

    var defaultRealm: Realm?
    var defaultConfiguration: Realm.Configuration
    let defaultQueue = dispatch_queue_create("default-realm-write-queue", nil)

    init(configuration: Realm.Configuration) {
        defaultConfiguration = configuration
        dispatch_async(defaultQueue) {
            if self.defaultRealm != nil {
                self.defaultRealm?.invalidate()
            }
            self.defaultRealm = try? Realm(configuration: configuration)
        }
    }

    func read(block: realm_dispatch_block) -> Bool {
        if let realm = defaultRealm {
            dispatch_async(defaultQueue, {
                block(realm: realm)
            })
            return true
        }
        return false
    }

    func write(block: realm_dispatch_block) -> Bool {
        if let realm = defaultRealm {
            dispatch_async(defaultQueue, {
                block(realm: realm)
            })
            return true
        }
        return false
    }

}

extension Results {
    func toArray() -> [T] {
        return map { $0 }
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
