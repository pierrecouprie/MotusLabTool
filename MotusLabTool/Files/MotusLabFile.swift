//
//  MotusLabFile.swift
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

@objcMembers
class MotusLabFile: NSObject, NSCoding {
    var name: String!
    var version: String!
    var creationDate: Date!
    var modificationDate: Date!
    dynamic var sessions: [Session]!
    
    dynamic var toSave: Int = 0
    
    /*override var description: String {
        var output = "MotusLabFile name: " + self.name + ", version: " + self.version + ", creationDate: \(String(describing: self.creationDate)), modificationDate: \(String(describing: self.modificationDate))"
        for session in self.sessions {
            output += "\r   " + session.description
        }
        return output
    }*/
    
    struct PropertyKey {
        static let nameKey = "name"
        static let versionKey = "version"
        static let creationDateKey = "creationDate"
        static let modificationDateKey = "modificationDate"
        static let sessionsKey = "sessions"
        static let acousmoPropertiesKey = "acousmoProperties"
    }
    
    required override init() {
        super.init()
    }
    
    convenience init(name: String) {
        self.init()
        self.name = name
        self.creationDate = Date()
        self.version = String.motusLabToolVersion
        self.sessions = []
    }
    
    required init(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String
        self.version = aDecoder.decodeObject(forKey: PropertyKey.versionKey) as? String
        self.creationDate = aDecoder.decodeObject(forKey: PropertyKey.creationDateKey) as? Date
        self.modificationDate = aDecoder.decodeObject(forKey: PropertyKey.modificationDateKey) as? Date
        self.sessions = aDecoder.decodeObject(forKey: PropertyKey.sessionsKey) as? [Session]
    }
    
    func encode(with aCoder: NSCoder) {
        self.modificationDate = Date()
        aCoder.encode(self.name, forKey: PropertyKey.nameKey)
        aCoder.encode(self.version, forKey: PropertyKey.versionKey)
        aCoder.encode(self.creationDate, forKey: PropertyKey.creationDateKey)
        aCoder.encode(self.modificationDate, forKey: PropertyKey.modificationDateKey)
        aCoder.encode(self.sessions, forKey: PropertyKey.sessionsKey)
    }
    
    func createSession() -> Session {
        let newSession = Session(title: "Untitled", number: self.sessions.count, motusLabFile: self)
        var sessions = self.sessions!
        sessions.append(newSession)
        self.setValue(sessions, forKey: PropertyKey.sessionsKey)
        self.save()
        Swift.print("MotusLabFile > createSession > " + newSession.description)
        return newSession
    }
    
    func save() {
        self.setValue(self.toSave + 1, forKey: "toSave")
    }
}

@objcMembers
class Session: NSObject, NSCoding {
    var id: String!
    dynamic var title: String! {
        didSet {
            self.motusLabFile.save()
        }
    }
    dynamic var information: String! {
        didSet {
            self.motusLabFile.save()
        }
    }
    dynamic var duration: Float = 0
    var audioFile: URL!
    var audioFormat: String = AudioFormat.pcm
    var consoleAControllers = [Bool](repeating: true, count: 129)
    var consoleBControllers = [Bool](repeating: true, count: 129)
    var markers: [Marker]!
    var markerCount: Int = 0
    dynamic var isRecording = false
    
    /*override var description: String {
        var output = "Session id: " + self.id + "title: " + self.title + " information: " + self.information + " duration: \(self.duration) audioFormat: " + self.audioFormat
        for marker in self.markers {
            output += "\r      " + marker.description
        }
        return output
    }*/
    
    weak var motusLabFile: MotusLabFile!
    
    struct PropertyKey {
        static let idKey = "id"
        static let titleKey = "title"
        static let informationKey = "information"
        static let durationKey = "duration"
        static let audioFileKey = "audioFile"
        static let audioFormatKey = "audioFormat"
        static let consoleAControllersKey = "consoleAControllers"
        static let consoleBControllersKey = "consoleBControllers"
        static let markersKey = "markers"
        static let markerCountKey = "markerCount"
        static let motusLabFileKey = "motusLabFile"
        
        static let isRecordingKey = "isRecording"
    }
    
    required override init() {
        super.init()
    }
    
    convenience init(title: String, number: Int, motusLabFile: MotusLabFile) {
        self.init()
        self.title = title
        self.information = ""
        self.id = UUID().uuidString
        self.duration = 0
        self.markers = []
        self.motusLabFile = motusLabFile
    }
    
    required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? String
        self.title = aDecoder.decodeObject(forKey: PropertyKey.titleKey) as? String
        self.information = aDecoder.decodeObject(forKey: PropertyKey.informationKey) as? String
        self.duration = aDecoder.decodeFloat(forKey: PropertyKey.durationKey)
        if let fileUrl = aDecoder.decodeObject(forKey: PropertyKey.audioFileKey) as? URL {
            self.audioFile = fileUrl
        }
        self.audioFormat = aDecoder.decodeObject(forKey: PropertyKey.audioFormatKey) as! String
        self.consoleAControllers = aDecoder.decodeObject(forKey: PropertyKey.consoleAControllersKey) as! [Bool]
        self.consoleBControllers = aDecoder.decodeObject(forKey: PropertyKey.consoleBControllersKey) as! [Bool]
        self.markers = aDecoder.decodeObject(forKey: PropertyKey.markersKey) as? [Marker]
        self.markerCount = aDecoder.decodeInteger(forKey: PropertyKey.markerCountKey)
        self.motusLabFile = aDecoder.decodeObject(forKey: PropertyKey.motusLabFileKey) as? MotusLabFile
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKey.idKey)
        aCoder.encode(self.title, forKey: PropertyKey.titleKey)
        aCoder.encode(self.information, forKey: PropertyKey.informationKey)
        aCoder.encode(self.duration, forKey: PropertyKey.durationKey)
        aCoder.encode(self.audioFile, forKey: PropertyKey.audioFileKey)
        aCoder.encode(self.audioFormat, forKey: PropertyKey.audioFormatKey)
        aCoder.encode(self.consoleAControllers, forKey: PropertyKey.consoleAControllersKey)
        aCoder.encode(self.consoleBControllers, forKey: PropertyKey.consoleBControllersKey)
        aCoder.encode(self.markers, forKey: PropertyKey.markersKey)
        aCoder.encode(self.markerCount, forKey: PropertyKey.markerCountKey)
        aCoder.encode(self.motusLabFile, forKey: PropertyKey.motusLabFileKey)
    }
    
    func addMarker(_ marker: Marker) {
        self.markers.append(marker)
        self.setValue(self.markers.count, forKey: PropertyKey.markerCountKey)
        self.motusLabFile.save()
        Swift.print("Session > addMarker > " + marker.description)
    }
}

@objcMembers
class Marker: NSObject, NSCoding, NSCopying {
    
    dynamic var title: String = ""
    dynamic var date: Float = 0
    
    /*override var description: String {
        return "Marker title: " + self.title + " date: \(self.date)"
    }*/
    
    struct PropertyKey {
        static let titleKey = "title"
        static let dateKey = "date"
    }
    
    required override init() {
        super.init()
    }
    
    convenience init(title: String, date: Float) {
        self.init()
        self.title = title
        self.date = date
    }
    
    required init(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObject(forKey: PropertyKey.titleKey) as! String
        self.date = aDecoder.decodeFloat(forKey: PropertyKey.dateKey)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: PropertyKey.titleKey)
        aCoder.encode(self.date, forKey: PropertyKey.dateKey)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Marker(title: self.title, date: self.date)
        return copy
    }
    
}
