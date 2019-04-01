//
//  Date+Format.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 07.03.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation

extension Date {
    public var formatted: String {
        let date = self
        if Calendar.current.isDateInToday(date) {
            return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        }else{
            let day = Calendar.current.startOfDay(for: date)
            if day.timeIntervalSinceNow >= -(60*60*24*6) { // last six days in seconds
                // Display Weekday
                let f = DateFormatter()
                f.locale = Locale.autoupdatingCurrent
                let n = Calendar.current.component(.weekday, from: day)-1
                let weekday = f.weekdaySymbols[n]
                return weekday
            }else{
                // Display Date
                return DateFormatter.localizedString(from: day, dateStyle: .short, timeStyle: .none)
            }
        }
    }
}
