//
//  LeagueAssetManager.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 18..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Alamofire
import AlamofireImage

struct LeagueAssetManager {

    static private let cache = AutoPurgingImageCacheWithDisk()
    static private var version = StoredProperty(key: "client_version")
    static private var defaultVersion = "5.22.3"

    static func buildProfileIconUrl(iconId: Int) -> String {
        return "http://ddragon.leagueoflegends.com/cdn/\(version.value ?? defaultVersion)/img/profileicon/\(iconId).png"
    }

    static func updateAssetClientVersion(callback: dispatch_block_t) {
        if LeagueAssetManager.version.value == nil {
            RiotAPI.getClientVersion(XMPPService.sharedInstance.region ?? LeagueServer.byCurrentLocale()) {
                if let newVersion = $0 {
                    LeagueAssetManager.version.value = newVersion
                    callback()
                } else {
                    #if DEBUG
                        print("An error occured while fetching client version")
                    #endif
                }
            }
        } else {
            callback()
        }
    }

    static func getProfileIcon(iconId: Int, callback: ((UIImage?)->Void)) {

        if iconId < 0 {
            callback(nil)

        } else if let image = cache.imageWithIdentifier("\(iconId).png") {
            callback(image)

        } else {
            updateAssetClientVersion {
                let url = buildProfileIconUrl(iconId)
                let URLRequest = NSURLRequest(URL: NSURL(string: url)!)

                Alamofire.request(.GET, url)
                    .responseImage { response in
                        if let image = response.result.value {
                            #if DEBUG
                                print("image downloaded: \(image)")
                            #endif
                            cache.addImage(image, forRequest: URLRequest)
                            callback(image)
                        } else {
                            #if DEBUG
                                print("An error occured while downloading image from " + url)
                            #endif
                            version.value = nil
                            callback(nil)
                        }
                }
            }
        }

    }

    static func drawProfileIcon(iconId: Int, view: UIImageView) {

        if iconId < 0 {
            view.image = UIImage(named: "profile_unknown")

        } else if let image = cache.imageWithIdentifier("\(iconId).png") {
            view.image = image

        } else {
            view.image = UIImage(named: "profile_unknown")
            updateAssetClientVersion {
                let url = buildProfileIconUrl(iconId)
                let URLRequest = NSURLRequest(URL: NSURL(string: url)!)

                Alamofire.request(.GET, url)
                    .responseImage { response in
                        if let image = response.result.value {
                            #if DEBUG
                                print("image downloaded: \(image)")
                            #endif
                            cache.addImage(image, forRequest: URLRequest)
                            view.crossfade(image)
                        } else {
                            #if DEBUG
                                print("An error occured while downloading image from " + url)
                            #endif
                            version.value = nil
                        }
                }
            }
        }
    }
}

class AutoPurgingImageCacheWithDisk : AutoPurgingImageCache {

    init() {
        super.init()
        createAssetDirectoryIfNotExist()
    }

    override func imageWithIdentifier(identifier: String) -> Image? {
        var image = super.imageWithIdentifier(identifier)
        if image == nil {
            if let split = try? identifier.URLString.split("/"), key = split.last {
                if hasCache(key) {
                    image = loadImageFromPath(generatePath(key))
                    if image != nil {
                        #if DEBUG
                            print("image loaded from: " + generatePath(key))
                        #endif
                        super.addImage(image!, withIdentifier: identifier)
                    }
                }
            }
        }
        return image
    }

    override func addImage(image: Image, withIdentifier identifier: String) {
        if let split = try? identifier.URLString.split("/"), key = split.last {
            super.addImage(image, withIdentifier: key)

            #if DEBUG
                print("image stored to: " + generatePath(key))
            #endif
            Async.background {
                if !self.hasCache(key) {
                    self.saveImage(image, path: self.generatePath(key))
                }
            }
        }
    }

    private func saveImage (image: UIImage, path: String) -> Bool {
        let pngImageData = UIImagePNGRepresentation(image)
        let result = pngImageData?.writeToFile(path, atomically: true)
        return result ?? false
    }

    private func loadImageFromPath(path: String) -> UIImage? {
        let image = Image(contentsOfFile: path)
        return image
    }

    private func hasCache (path: String) -> Bool {
        let checkValidation = NSFileManager.defaultManager()
        return checkValidation.fileExistsAtPath(generatePath(path))
    }

    private func createAssetDirectoryIfNotExist() {
        let libraryPath = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0] as String
        let assetPath = libraryPath + "/assets"
        let fileManager = NSFileManager.defaultManager()

        if !fileManager.fileExistsAtPath(assetPath) {
            do {
                try fileManager.createDirectoryAtPath(assetPath,
                    withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
    }

    private func generatePath(key: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0] as String
        return paths + "/assets/\(key)"
    }
}
