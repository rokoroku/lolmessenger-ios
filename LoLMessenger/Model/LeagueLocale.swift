//
//  LeagueLocale.swift
//  LoLMessenger
//
//  Created by Kim Young Rok on 2015. 11. 24..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Foundation

struct LeagueLocale: CustomStringConvertible {

    var locale: String
    var language: String
    var description: String {
        return locale
    }

    init (locale: String) {
        self.locale = locale
        self.language = try! locale.split("_")[0]
    }

    static let EN = LeagueLocale(locale: "en_US")
    static let ES = LeagueLocale(locale: "es_ES")
    static let FR = LeagueLocale(locale: "fr_FR")
    static let DE = LeagueLocale(locale: "de_DE")
    static let IT = LeagueLocale(locale: "it_IT")
    static let PL = LeagueLocale(locale: "pl_PL")
    static let EL = LeagueLocale(locale: "el_GR")
    static let RO = LeagueLocale(locale: "ro_RO")
    static let PT = LeagueLocale(locale: "pt_BR")
    static let TR = LeagueLocale(locale: "tr_TR")
    static let TH = LeagueLocale(locale: "th_TH")
    static let VN = LeagueLocale(locale: "vn_VN")
    static let ID = LeagueLocale(locale: "id_ID")
    static let RU = LeagueLocale(locale: "ru_RU")
    static let KO = LeagueLocale(locale: "ko_KR")
    static let ZH = LeagueLocale(locale: "zh_CN")
    static let TW = LeagueLocale(locale: "zh_TW")

    static let availableLocales = [EN, ES, FR, DE, IT, PL, EL, RO, PT, TR, TH, VN, ID, RU, KO, ZH, TW]

    static func getPreferredLocale() -> LeagueLocale? {
        let currentLocale:String = Localize.currentLanguage()
        if currentLocale.containsString("Hant") {
            return TW
        } else if (currentLocale.containsString("Hans")) {
            return ZH
        }

        for locale in availableLocales {
            if currentLocale.containsString(locale.language) {
                return locale
            }
        }
        return nil
    }

}