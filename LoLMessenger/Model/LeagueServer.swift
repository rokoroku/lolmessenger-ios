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

    init(name: String, host: String) {
        self.name = name
        self.host = host
    }

    static let NA = LeagueServer(name: "North America", host: "chat.na2.lol.riotgames.com")
    static let EUW = LeagueServer(name: "Europe West", host: "chat.enw1.lol.riotgames.com")
    static let EUNE = LeagueServer(name: "Europe Nordic & East", host: "chat.eun1.lol.riotgames.com")
    static let BR = LeagueServer(name: "Brazil", host: "chat.br.lol.riotgames.com")
    static let KR = LeagueServer(name: "Korea", host: "chat.kr.lol.riotgames.com")
    static let LAN = LeagueServer(name: "Latin America North", host: "chat.la1.lol.riotgames.com")
    static let LAS = LeagueServer(name: "Latin America South", host: "chat.la2.lol.riotgames.com")
    static let OCE = LeagueServer(name: "Oceania", host: "chat.oc1.lol.riotgames.com")
    static let TR = LeagueServer(name: "Turkey", host: "chat.tr.lol.riotgames.com")
    static let RU = LeagueServer(name: "Russia", host: "chat.ru.lol.riotgames.com")

}
