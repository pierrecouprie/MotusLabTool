//
//  AcousmoniumFile.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 30/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

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
    var showImage: Bool = true {
        didSet {
            //self.viewController.saveAcousmoniumFile(self)
        }
    }
    dynamic var acousmoLoudspeakers: [AcousmoLoudspeaker] = []
    
    /*weak var viewController: ViewController! {
        didSet {
            for loudspeaker in self.acousmoLoudspeakers {
                loudspeaker.acousmoniumFile = self
            }
        }
    }*/
    
    override var description: String {
        var output = "AcousmoniumFile id: " + self.id + ", name: " + self.name + ", version: " + self.version + ", showImage: \(self.showImage)"
        for loudspeaker in self.acousmoLoudspeakers {
            output += "\r   " + loudspeaker.description
        }
        return output
    }
    
    struct PropertyKey {
        static let idKey = "id"
        static let nameKey = "name"
        static let versionKey = "version"
        static let imageKey = "image"
        static let acousmoLoudspeakersKey = "acousmoLoudspeakers"
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
        self.acousmoLoudspeakers = aDecoder.decodeObject(forKey: PropertyKey.acousmoLoudspeakersKey) as! [AcousmoLoudspeaker]
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKey.idKey)
        aCoder.encode(self.name, forKey: PropertyKey.nameKey)
        aCoder.encode(self.version, forKey: PropertyKey.versionKey)
        aCoder.encode(self.image, forKey: PropertyKey.imageKey)
        aCoder.encode(self.acousmoLoudspeakers, forKey: PropertyKey.acousmoLoudspeakersKey)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func createLoudspeaker() {
        var previousConsole: Int = 0
        var previousInput = 0
        if self.acousmoLoudspeakers.count > 0 {
            previousConsole = self.acousmoLoudspeakers.last!.console
            previousInput = self.acousmoLoudspeakers.last!.input
        }
        previousInput += 1
        var acousmoLoudspeakers = self.acousmoLoudspeakers
        let newLoudspeaker = AcousmoLoudspeaker(title: "Untitled", input: previousInput, console: previousConsole)
        acousmoLoudspeakers.append(newLoudspeaker)
        newLoudspeaker.acousmoniumFile = self
        self.setValue(acousmoLoudspeakers, forKey: PropertyKey.acousmoLoudspeakersKey)
    }
    
    func removeLoudspeaker(_ acousmoLoudspeaker: AcousmoLoudspeaker) {
        var acousmoLoudspeakers = self.acousmoLoudspeakers
        
        for (index, loudspeaker) in acousmoLoudspeakers.enumerated() {
            if loudspeaker == acousmoLoudspeaker {
                acousmoLoudspeakers.remove(at: index)
                break
            }
        }
        self.setValue(acousmoLoudspeakers, forKey: PropertyKey.acousmoLoudspeakersKey)
    }
    
    func save() {
        //self.viewController.saveAcousmoniumFile(self)
    }
    
}

@objcMembers
class AcousmoLoudspeaker: NSObject, NSCoding {
    var title: String! {
        didSet {
            self.acousmoniumFile.save()
        }
    }
    var position: CGPoint! //saved when mouseUp
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
    
    override var description: String {
        return "AcousmoLoudspeaker title: " + self.title + ", position: \(String(describing: self.position)), input: \(String(describing: self.input)), console: \(String(describing: self.console)), color: \(String(describing: self.color))"
    }
    
    struct PropertyKey {
        static let titleKey = "title"
        static let positionKey = "position"
        static let inputKey = "input"
        static let consoleKey = "console"
        static let colorKey = "color"
    }
    
    required override init() {
        super.init()
    }
    
    convenience init(title: String, input: Int = 0, console: Int = 0) {
        self.init()
        self.title = title
        self.position = CGPoint(x: 0.5, y: 0.5)
        self.input = input
        self.console = console
        self.color = NSColor.black
    }
    
    required init(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObject(forKey: PropertyKey.titleKey) as? String
        self.position = aDecoder.decodePoint(forKey: PropertyKey.positionKey)
        self.input = aDecoder.decodeInteger(forKey: PropertyKey.inputKey)
        self.console = aDecoder.decodeInteger(forKey: PropertyKey.consoleKey)
        self.color = aDecoder.decodeObject(forKey: PropertyKey.colorKey) as? NSColor
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: PropertyKey.titleKey)
        aCoder.encode(self.position, forKey: PropertyKey.positionKey)
        aCoder.encode(self.input, forKey: PropertyKey.inputKey)
        aCoder.encode(self.console, forKey: PropertyKey.consoleKey)
        aCoder.encode(self.color, forKey: PropertyKey.colorKey)
    }
    
}

