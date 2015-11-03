//
//  LeagueServer.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 2..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Foundation

struct LeagueServer {

    var name: String
    var host: String
    var shorthand: String

    init(name: String, shorthand: String, host: String) {
        self.name = name
        self.shorthand = shorthand
        self.host = host
    }

    static let NA = LeagueServer(name: "North America", shorthand: "NA", host: "chat.na2.lol.riotgames.com")
    static let EUW = LeagueServer(name: "Europe West", shorthand: "EUW", host: "chat.enw1.lol.riotgames.com")
    static let EUNE = LeagueServer(name: "Europe Nordic & East", shorthand: "EUNE", host: "chat.eun1.lol.riotgames.com")
    static let BR = LeagueServer(name: "Brazil", shorthand: "BR",  host: "chat.br.lol.riotgames.com")
    static let KR = LeagueServer(name: "Korea", shorthand: "KR", host: "chat.kr.lol.riotgames.com")
    static let LAN = LeagueServer(name: "Latin America North", shorthand: "LAN", host: "chat.la1.lol.riotgames.com")
    static let LAS = LeagueServer(name: "Latin America South", shorthand: "LAS", host: "chat.la2.lol.riotgames.com")
    static let OCE = LeagueServer(name: "Oceania", shorthand: "OCE", host: "chat.oc1.lol.riotgames.com")
    static let TR = LeagueServer(name: "Turkey", shorthand: "TR", host: "chat.tr.lol.riotgames.com")
    static let RU = LeagueServer(name: "Russia", shorthand: "RU", host: "chat.ru.lol.riotgames.com")

    static let availableRegions = [NA, EUW, EUNE, BR, KR, LAN, LAS, OCE, TR, RU]

    static func forName(name: String) -> LeagueServer? {
        for region in availableRegions {
            if region.name == name {
                return region
            }
        }
        return nil
    }

    static func forShorthand(shorthand: String?) -> LeagueServer? {
        for region in availableRegions {
            if region.shorthand == shorthand {
                return region
            }
        }
        return nil
    }

}
