//
//  StringExtenisions.swift
//  LoLMessenger
//
//  Created by Young Rok Kim on 2015. 10. 2..
//  Copyright © 2015년 rokoroku. All rights reserved.
//

import Foundation

extension String {

    func split(splitter: String) throws -> Array<String> {
        let regEx = try NSRegularExpression(pattern: splitter, options: NSRegularExpressionOptions())
        let stop = "&&"
        let modifiedString = regEx.stringByReplacingMatchesInString (self,
            options: NSMatchingOptions(),
            range: NSMakeRange(0, self.characters.count),
            withTemplate: stop)
        return modifiedString.componentsSeparatedByString(stop)
    }

    func substringWithRange(start: Int, end: Int) -> String
    {
        if (start < 0 || start > self.characters.count) {
            print("start index \(start) out of bounds")
            return ""
        } else if (end < 0 || end > self.characters.count) {
            print("end index \(end) out of bounds")
            return ""
        }
        let range = Range(start: self.startIndex.advancedBy(start), end: self.startIndex.advancedBy(end))
        return self.substringWithRange(range)
    }

    func substringWithRange(start: Int, location: Int) -> String
    {
        if (start < 0 || start > self.characters.count)
        {
            print("start index \(start) out of bounds")
            return ""
        }
        else if location < 0 || start + location > self.characters.count
        {
            print("end index \(start + location) out of bounds")
            return ""
        }
        let range = Range(start: self.startIndex.advancedBy(start), end: self.startIndex.advancedBy(start + location))
        return self.substringWithRange(range)
    }

    func trim() -> String {
        return self.stringByReplacingOccurrencesOfString(" ", withString: "")
    }

    func equalsIgnoreCase(aString: String) -> Bool {
        return self.caseInsensitiveCompare(aString) == .OrderedSame
    }

    func isEmpty() -> Bool {
        return isEmpty || stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")).isEmpty
    }

    func encodeXML() -> String {
        var encodedString = self.stringByReplacingOccurrencesOfString("&", withString: "&amp;")
        encodedString = encodedString.stringByReplacingOccurrencesOfString("\"", withString: "&quot;")
        encodedString = encodedString.stringByReplacingOccurrencesOfString("'", withString: "&#x27;")
        encodedString = encodedString.stringByReplacingOccurrencesOfString(">", withString: "&gt;")
        encodedString = encodedString.stringByReplacingOccurrencesOfString("<", withString: "&lt;")
        return encodedString
    }
    
    func decodeXML() -> String {
        var decodedString = self.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&quot;", withString: "\"")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&#x27;", withString: "'")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&#x39;", withString: "'")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&#x92;", withString: "'")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&#x96;", withString: "'")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&gt;", withString: ">")
        decodedString = decodedString.stringByReplacingOccurrencesOfString("&lt;", withString: "<")
        return decodedString
    }

    func encodeURL() -> String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }

    func parseDateTime() -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        if let date = dateFormatter.dateFromString(self) {
            return date
        }
        return nil
    }
}

extension NSDate {
    func format(dateFormat:String) -> String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.stringFromDate(self)
    }

    func formatDate(style: NSDateFormatterStyle) -> String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = style
        return dateFormatter.stringFromDate(self)
    }

    func formatFromCompenents(styleAttitude: NSDateFormatterStyle, year: Bool = true, month: Bool = true, day: Bool = true, hour: Bool = true, minute: Bool = true, second: Bool = true) -> String {
        let long = styleAttitude == .LongStyle || styleAttitude == .FullStyle ? true : false
        var comps = ""

        if year { comps += long ? "yyyy" : "yy" }
        if month { comps += long ? "MMMM" : "MMM" }
        if day { comps += long ? "dd" : "d" }

        if hour { comps += long ? "HH" : "H" }
        if minute { comps += long ? "mm" : "m" }
        if second { comps += long ? "ss" : "s" }

        let format = NSDateFormatter.dateFormatFromTemplate(comps, options: 0, locale: NSLocale.currentLocale())
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        return formatter.stringFromDate(self)
    }
}
