//
//  RealmExtensions.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 15..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import RealmSwift

typealias realm_dispatch_block = ((realm: Realm) -> Void)

class RealmWrapper {
    // Create a separate thread (with a serial dispatch queue) for Realm writes
    // From Realm docs: "Please note that writes block each other, and will block the thread they are made on if other writes are in progress. This is similar to any other persistence solution, so we do recommend that you use the usual best-practices for that situation, namely offloading your writes to a separate thread"

    private var realm: Realm?
    private var configuration: Realm.Configuration
    private let dedicatedQueue = dispatch_queue_create("default-realm-write-queue", nil)

    init(configuration config: Realm.Configuration) {
        configuration = config

        dispatch_async(dedicatedQueue) {
            self.realm = try? Realm(configuration: config)
        }
    }

    deinit {
        dispatch_async(dedicatedQueue) {
            self.realm?.invalidate()
        }
    }

    func read(block: realm_dispatch_block) -> Bool {
        if let realm = realm {
            dispatch_async(dedicatedQueue, {
                block(realm: realm)
            })
            return true
        }
        return false
    }

    func write(block: realm_dispatch_block) -> Bool {
        if let realm = realm {
            dispatch_async(dedicatedQueue, {
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

    func remove() -> Bool {
        if let realm = self.realm {
            do {
                try realm.write {
                    realm.delete(self)
                }
            } catch {
                return false
            }
        }
        return true
    }

    func update(block: dispatch_block_t) -> Bool {
        if let realm = realm {
            do {
                try realm.write(block)
            } catch {
                return false
            }
        } else {
            block()
        }
        return true
    }
}
