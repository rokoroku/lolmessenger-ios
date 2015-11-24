//
//  RiotAPIClient.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 7..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Alamofire
import SwiftyJSON

class AccountInfo {
    var platformId: String;
    var accountId: Int;

    init(platformId: String, accountId: Int) {
        self.platformId = platformId;
        self.accountId = accountId;
    }
}

class RiotACS {

    class func getAccountInfo(summonerName name: String, region: LeagueServer, callback: ((AccountInfo?) -> Void)) {
        Alamofire.request(.GET, "https://acs.leagueoflegends.com/v1/players",
            parameters: ["name": name, "region": region.shorthand])
            .responseJSON { response in
                debugPrint(response)
                if let value = response.result.value {
                    let object = JSON(value)
                    if let platformId = object["platformId"].string,
                        let accountId = object["accountId"].int {
                            callback(AccountInfo(platformId: platformId, accountId: accountId))
                            return
                    }
                }
                callback(nil)
        }
    }

    class func getSummonerByAccountInfo(accountInfo info: AccountInfo, callback: ((LeagueRoster?) -> Void)) {
        Alamofire.request(.GET,
            "https://acs.leagueoflegends.com/v1/stats/player_history/\(info.platformId)/\(info.accountId)")
            .responseJSON { response in
                debugPrint(response)
                if let value = response.result.value {
                    let object = JSON(value)
                    let player = object["games"]["games"][0]["participantIdentities"][0]["player"]
                    if let id = player["summonerId"].int,
                        let nick = player["summonerName"].string,
                        let icon = player["profileIcon"].int
                    {
                        let roster = LeagueRoster(numberId: id, nickname: nick)
                        roster.profileIcon = icon
                        callback(roster)
                        return
                    }
                }
                callback(nil)
        }
    }

    class func getSummonerByName(summonerName name: String, region: LeagueServer, callback: ((LeagueRoster?) -> Void)) {

        let failback: ((LeagueRoster?) -> Void) = {
            if let summoner = $0 {
                callback(summoner)
            } else {
                RiotAPI.getSummonerByName(summonerName: name, region: region, callback: callback)
            }
        }

        RiotACS.getAccountInfo(summonerName: name, region: region) {
            if let info = $0 {
                getSummonerByAccountInfo(accountInfo: info) { summoner in
                    failback(summoner)
                }
            } else {
                failback(nil)
            }
        }

    }
}

class RiotAPI {

    static let keys: [String] = {
        if let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist"),
            dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
            riotAPI = dict["RiotAPI"] as? [String: AnyObject],
            apiKeys = riotAPI["APIKey"] as? [String] {
                return apiKeys
        }
        return ["59fc64a9-b530-4ed9-b161-6343fb5f935d"]
    }()
    static var randomKey: String {
        return RiotAPI.keys[random()%keys.count]
    }

    class func getBaseString(region: LeagueServer) -> String {
        return "https://" + region.shorthand.lowercaseString + ".api.pvp.net/api/lol/" + region.shorthand.lowercaseString
    }

    class func getClientVersion(region: LeagueServer, callback: ((String?) -> Void)) {
        let url = "https://global.api.pvp.net/api/lol/static-data/" + region.shorthand.lowercaseString + "/v1.2/versions" + "?api_key=" + randomKey
        Alamofire.request(.GET, url).responseJSON { response in
            if let value = response.result.value {
                let versions = JSON(value).arrayValue
                if !versions.isEmpty {
                    callback(versions[0].string)
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }

    class func getSummonerById(summonerId id: String, region: LeagueServer, callback: ((LeagueRoster?) -> Void)) {
        let summonerId = id.stringByReplacingOccurrencesOfString("sum", withString: "")
        let url = getBaseString(region) + "/v1.4/summoner/" + summonerId + "?api_key=" + randomKey
        Alamofire.request(.GET, url).responseJSON { response in
            if let value = response.result.value {
                let summoner = JSON(value)[summonerId]
                if let nick = summoner["name"].string,
                    let icon = summoner["profileIconId"].int,
                    let level = summoner["summonerLevel"].int
                {
                    let roster = LeagueRoster(stringId: id, nickname: nick)
                    roster.profileIcon = icon
                    roster.level = level
                    callback(roster)
                    return
                }
            }
            callback(nil)
        }
    }

    class func getSummonerByName(summonerName name: String, region: LeagueServer, callback: ((LeagueRoster?) -> Void)) {
        let summonerName = name.stringByReplacingOccurrencesOfString(" ", withString: "")
        let url = getBaseString(region) + "/v1.4/summoner/by-name/" + summonerName.encodeURL() + "?api_key=" + randomKey
        Alamofire.request(.GET, url).responseJSON { response in
            if let value = response.result.value {
                let summoner = JSON(value)[summonerName]
                if let id = summoner["id"].int,
                    let nick = summoner["name"].string,
                    let icon = summoner["profileIconId"].int,
                    let level = summoner["summonerLevel"].int
                {
                    let roster = LeagueRoster(numberId: id, nickname: nick)
                    roster.profileIcon = icon
                    roster.level = level
                    callback(roster)
                    return
                }
            }
            callback(nil)
        }
    }

    class func getChampionData(region: LeagueServer, callback: ((JSON?) -> Void)) {
        var url = "https://global.api.pvp.net/api/lol/static-data/\(region.shorthand.lowercaseString)/v1.2/champion?api_key=\(randomKey)"
        if let locale = LeagueLocale.getPreferredLocale() {
            url += "&locale=\(locale.description)"
        }
        Alamofire.request(.GET, url).responseJSON { response in
            if response.result.isSuccess {
                if let value = response.result.value {
                    let data = JSON(value)
                    callback(data)
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
}
