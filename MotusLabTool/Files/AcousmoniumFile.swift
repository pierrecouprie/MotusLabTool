//
//  AcousmoniumFile.swift
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

import Cocoa

@objcMembers
class AcousmoniumFile: NSObject, NSCoding {
    var id: String!
    var name: String! {
        didSet {
            self.save()
        }
    }
    var version: String!
    var image: Data! {
        didSet {
            self.save()
        }
    }
    var showImage: Bool = false {
        didSet {
            self.save()
        }
    }
    dynamic var acousmoniumLoudspeakers: [AcousmoniumLoudspeaker] = []
    dynamic var selectedLoudspeakerIndex = IndexSet()
    dynamic var toSave: Int = 0
    
    struct PropertyKey {
        static let idKey = "id"
        static let nameKey = "name"
        static let versionKey = "version"
        static let imageKey = "image"
        static let showImageKey = "showImage"
        static let acousmoniumLoudspeakersKey = "acousmoniumLoudspeakers"
    }
    
    required override init() {
        super.init()
    }
    
    convenience init(name: String) {
        self.init()
        self.id = UUID().uuidString
        self.name = name
        self.version = String.motusLabToolVersion
    }
    
    required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? String
        self.name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String
        self.version = aDecoder.decodeObject(forKey: PropertyKey.versionKey) as? String
        self.image = aDecoder.decodeObject(forKey: PropertyKey.imageKey) as? Data
        self.showImage = aDecoder.decodeBool(forKey: PropertyKey.showImageKey)
        self.acousmoniumLoudspeakers = aDecoder.decodeObject(forKey: PropertyKey.acousmoniumLoudspeakersKey) as! [AcousmoniumLoudspeaker]
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKey.idKey)
        aCoder.encode(self.name, forKey: PropertyKey.nameKey)
        aCoder.encode(self.version, forKey: PropertyKey.versionKey)
        aCoder.encode(self.image, forKey: PropertyKey.imageKey)
        aCoder.encode(self.showImage, forKey: PropertyKey.showImageKey)
        aCoder.encode(self.acousmoniumLoudspeakers, forKey: PropertyKey.acousmoniumLoudspeakersKey)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func createLoudspeaker() {
        var previousConsole: Int = 0
        var previousInput = 0
        var previousTitle = "Untitled"
        if self.acousmoniumLoudspeakers.count > 0 {
            previousConsole = self.acousmoniumLoudspeakers.last!.console
            previousInput = self.acousmoniumLoudspeakers.last!.input
            previousTitle = self.acousmoniumLoudspeakers.last!.title
        }
        previousInput += 1
        var acousmoLoudspeakers = self.acousmoniumLoudspeakers
        let newLoudspeaker = AcousmoniumLoudspeaker(title: previousTitle, input: previousInput, console: previousConsole)
        acousmoLoudspeakers.append(newLoudspeaker)
        newLoudspeaker.acousmoniumFile = self
        self.setValue(acousmoLoudspeakers, forKey: PropertyKey.acousmoniumLoudspeakersKey)
        self.save()
    }
    
    func removeLoudspeaker(_ acousmoLoudspeaker: AcousmoniumLoudspeaker) {
        var acousmoniumLoudspeakers = self.acousmoniumLoudspeakers
        
        for (index, loudspeaker) in acousmoniumLoudspeakers.enumerated() {
            if loudspeaker == acousmoLoudspeaker {
                acousmoniumLoudspeakers.remove(at: index)
                break
            }
        }
        self.setValue(acousmoniumLoudspeakers, forKey: PropertyKey.acousmoniumLoudspeakersKey)
        self.save()
    }
    
    func save() {
        self.setValue(self.toSave + 1, forKey: "toSave")
    }
    
}

@objcMembers
class AcousmoniumLoudspeaker: NSObject, NSCoding {
    var title: String! {
        didSet {
            self.acousmoniumFile.save()
        }
    }
    var x: Float = 0.5
    var y: Float = 0.5
    var input: Int = 0 {
        didSet {
            self.acousmoniumFile.save()
        }
    }
    var console: Int = 0 {
        didSet {
            self.acousmoniumFile.save()
        }
    }
    var color: NSColor! {
        didSet {
            self.acousmoniumFile.save()
        }
    }
    
    weak var acousmoniumFile: AcousmoniumFile!
    
    struct PropertyKey {
        static let titleKey = "title"
        static let xKey = "x"
        static let yKey = "y"
        static let inputKey = "input"
        static let consoleKey = "console"
        static let colorKey = "color"
        static let acousmoniumFileKey = "acousmoniumFile"
    }
    
    required override init() {
        super.init()
    }
    
    convenience init(title: String, input: Int = 0, console: Int = 0) {
        self.init()
        self.title = title
        self.input = input
        self.console = console
        self.color = NSColor.black
    }
    
    required init(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObject(forKey: PropertyKey.titleKey) as? String
        self.x = aDecoder.decodeFloat(forKey: PropertyKey.xKey)
        self.y = aDecoder.decodeFloat(forKey: PropertyKey.yKey)
        self.input = aDecoder.decodeInteger(forKey: PropertyKey.inputKey)
        self.console = aDecoder.decodeInteger(forKey: PropertyKey.consoleKey)
        self.color = aDecoder.decodeObject(forKey: PropertyKey.colorKey) as? NSColor
        self.acousmoniumFile = aDecoder.decodeObject(forKey: PropertyKey.acousmoniumFileKey) as? AcousmoniumFile
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: PropertyKey.titleKey)
        aCoder.encode(self.x, forKey: PropertyKey.xKey)
        aCoder.encode(self.y, forKey: PropertyKey.yKey)
        aCoder.encode(self.input, forKey: PropertyKey.inputKey)
        aCoder.encode(self.console, forKey: PropertyKey.consoleKey)
        aCoder.encode(self.color, forKey: PropertyKey.colorKey)
        aCoder.encode(self.acousmoniumFile, forKey: PropertyKey.acousmoniumFileKey)
    }
    
}

