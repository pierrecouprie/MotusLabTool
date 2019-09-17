//
//  MIDIControllerEvent.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

class MIDIControllerEvent: NSObject, NSCoding {
    
    var date: Float = 0
    var console: Int = 0
    var channel: Int = 0
    var number: Int = 0
    var value: Int = 0
    var feedback: String = ""
    
    override var description: String {
        return "MIDIControllerEvent date: \(self.date) console: \(self.console) channel: \(self.channel) number: \(self.number) value: \(self.value)"
    }
    
    struct PropertyKey {
        static let dateKey = "date"
        static let consoleKey = "console"
        static let channelKey = "channel"
        static let numberKey = "number"
        static let valueKey = "value"
    }
    
    override required init() {
        super.init()
    }
    
    convenience init(date: Float) {
        self.init()
        self.date = date
        self.feedback = "Unknown"
    }
    
    convenience init(date: Float, console: Int, channel: Int, number: Int, value: Int) {
        self.init()
        self.date = date
        self.console = console
        self.channel = channel
        self.number = number
        self.value = value
        self.feedback = "Controller \(number), value: \(value), channel: \(channel)"
    }
    
    required init(coder aDecoder: NSCoder) {
        self.date = aDecoder.decodeFloat(forKey: PropertyKey.dateKey)
        self.console = aDecoder.decodeInteger(forKey: PropertyKey.consoleKey)
        self.channel = aDecoder.decodeInteger(forKey: PropertyKey.channelKey)
        self.number = aDecoder.decodeInteger(forKey: PropertyKey.numberKey)
        self.value = aDecoder.decodeInteger(forKey: PropertyKey.valueKey)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.date, forKey: PropertyKey.dateKey)
        aCoder.encode(self.console, forKey: PropertyKey.consoleKey)
        aCoder.encode(self.channel, forKey: PropertyKey.channelKey)
        aCoder.encode(self.number, forKey: PropertyKey.numberKey)
        aCoder.encode(self.value, forKey: PropertyKey.valueKey)
    }
    
    func copyWithoutDate() -> MIDIControllerEvent {
        let copy = MIDIControllerEvent(date: 0, console: self.console, channel: self.channel, number: self.number, value: self.value)
        return copy
    }
    
}
