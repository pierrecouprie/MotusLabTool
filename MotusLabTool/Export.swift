//
//  Export.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 08/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

class Export: NSObject {
    
    var fileURL: URL!
    var url: URL!
    weak var motusLabFile: MotusLabFile!
    var midiControllerEvents: [MIDIControllerEvent]!
    
    init(_ url: URL, fileURL: URL, motusLabFile: MotusLabFile) {
        super.init()
        self.url = url
        self.fileURL = fileURL
        self.motusLabFile = motusLabFile
    }
    
    /// Export current project
    func export() {
        self.createDirectories()
        self.copyFiles()
        self.createJSON()
    }
    
    func createDirectories() {
            
        let audioUrl = self.url.appendingPathComponent(FilePath.audio)
        let movieUrl = self.url.appendingPathComponent(FilePath.movie)
        var authorized: Int = 0
        
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: self.url, withIntermediateDirectories: false, attributes: nil)
        } catch {
            Swift.print("Export: createDirectories() Cannot create folder to url (" + self.url.path + ")!")
        }
        
        do {
            try fileManager.createDirectory(at: audioUrl, withIntermediateDirectories: false, attributes: nil)
            authorized += 1
        } catch {
            Swift.print("Export: createDirectories() Cannot create audio subfolder!")
        }
        
        do {
            try fileManager.createDirectory(at: movieUrl, withIntermediateDirectories: false, attributes: nil)
            authorized += 1
        } catch {
            Swift.print("Export: createDirectories() Cannot create movie subfolder!")
        }
        
    }
    
    func copyFiles() {
        let fileManager = FileManager.default
        for session in self.motusLabFile.sessions {
            
            let audioExtension = session.audioFormat
            let audioURL = self.fileURL.appendingPathComponent(FilePath.audio).appendingPathComponent(session.id).appendingPathExtension(audioExtension)
            
            let cameraAURL = self.fileURL.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.A).appendingPathExtension(FileExtension.mp4)
            let cameraBURL = self.fileURL.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.B).appendingPathExtension(FileExtension.mp4)
            let cameraCURL = self.fileURL.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.C).appendingPathExtension(FileExtension.mp4)
            let cameraDURL = self.fileURL.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.D).appendingPathExtension(FileExtension.mp4)
            
            if fileManager.fileExists(atPath: audioURL.path) {
                do {
                    try fileManager.copyItem(at: audioURL, to: self.url.appendingPathComponent(FilePath.audio).appendingPathComponent(session.id).appendingPathExtension(audioExtension))
                } catch let error as NSError {
                    Swift.print("Export: copyFiles() Error copying file from \(audioURL) to \(self.url.appendingPathComponent(session.id).appendingPathExtension(audioExtension)), context: " + error.localizedDescription)
                }
            }
            
            if fileManager.fileExists(atPath: cameraAURL.path) {
                do {
                    try fileManager.copyItem(at: cameraAURL, to: self.url.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.A).appendingPathExtension(FileExtension.mp4))
                } catch let error as NSError {
                    Swift.print("Export: copyFiles() Error copying file from \(cameraAURL) to \(self.url.appendingPathComponent(session.id + FilePath.A).appendingPathExtension(FileExtension.mp4)), context: " + error.localizedDescription)
                }
            }
            
            if fileManager.fileExists(atPath: cameraBURL.path) {
                do {
                    try fileManager.copyItem(at: cameraBURL, to: self.url.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.B).appendingPathExtension(FileExtension.mp4))
                } catch let error as NSError {
                    Swift.print("Export: copyFiles() Error copying file from \(cameraBURL) to \(self.url.appendingPathComponent(session.id + FilePath.B).appendingPathExtension(FileExtension.mp4)), context: " + error.localizedDescription)
                }
            }
            
            if fileManager.fileExists(atPath: cameraCURL.path) {
                do {
                    try fileManager.copyItem(at: cameraCURL, to: self.url.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.C).appendingPathExtension(FileExtension.mp4))
                } catch let error as NSError {
                    Swift.print("Export: copyFiles() Error copying file from \(cameraCURL) to \(self.url.appendingPathComponent(session.id + FilePath.C).appendingPathExtension(FileExtension.mp4)), context: " + error.localizedDescription)
                }
            }
            
            if fileManager.fileExists(atPath: cameraDURL.path) {
                do {
                    try fileManager.copyItem(at: cameraDURL, to: self.url.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.D).appendingPathExtension(FileExtension.mp4))
                } catch let error as NSError {
                    Swift.print("Export: copyFiles() Error copying file from \(cameraDURL) to \(self.url.appendingPathComponent(session.id + FilePath.D).appendingPathExtension(FileExtension.mp4)), context: " + error.localizedDescription)
                }
            }
            
        }
    }
    
    func createJSON() {
        var error: NSError?
        if let os = OutputStream(toFileAtPath: self.url.appendingPathComponent(FilePath.motusLabFile).appendingPathExtension(FileExtension.json).path, append: false) {
            let convertedData = self.convertToJSON()
            os.open()
            JSONSerialization.writeJSONObject(convertedData, to: os, options: [], error: &error)
            os.close()
            if error != nil {
                Swift.print("Export: createJSON Unable to export to JSON. context: \(error!.localizedDescription)")
            }
        } else {
            Swift.print("Export: createJSON Unable to open output stream!")
        }
    }
    
    /// Convert motusLab and midiController files to a ready to JSON dictionary
    ///
    /// - Returns: Dictionary
    func convertToJSON() -> [String:Any] {
        var data = [String:Any]()
        
        //Add metadata
        var file_metadata = [String:Any]()
        file_metadata[MotusLabFile.PropertyKey.nameKey] = self.motusLabFile.name
        file_metadata[MotusLabFile.PropertyKey.versionKey] = self.motusLabFile.version
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss:SSS"
        file_metadata[MotusLabFile.PropertyKey.creationDateKey] = dateFormater.string(from: self.motusLabFile.creationDate)
        data[JSONKey.file_metadata] = file_metadata
        
        //Add sessions
        var sessions = [[String:Any]]()
        for session in self.motusLabFile.sessions {
            var newSession = [String:Any]()
            newSession[Session.PropertyKey.idKey] = session.id
            newSession[Session.PropertyKey.titleKey] = session.title
            newSession[Session.PropertyKey.informationKey] = session.information
            newSession[Session.PropertyKey.durationKey] = session.duration
            newSession[Session.PropertyKey.audioFormatKey] = session.audioFormat
            newSession[Session.PropertyKey.consoleAControllersKey] = self.convertConsoleController(session.consoleAControllers)
            newSession[Session.PropertyKey.consoleBControllersKey] = self.convertConsoleController(session.consoleBControllers)
            
            //Add markers
            var markers = [[String:Any]]()
            for marker in session.markers {
                var newMarker = [String:Any]()
                newMarker[Marker.PropertyKey.titleKey] = marker.title
                newMarker[Marker.PropertyKey.dateKey] = marker.date
                markers.append(newMarker)
            }
            
            newSession[Session.PropertyKey.markersKey] = markers
            
            //Add MIDI events
            if let midiEvents = self.midiEvents(from: session.id) {
                var events = [[String:Any]]()
                for event in midiEvents {
                    var newEvent = [String:Any]()
                    newEvent[MIDIControllerEvent.PropertyKey.consoleKey] = event.console
                    newEvent[MIDIControllerEvent.PropertyKey.channelKey] = event.channel
                    newEvent[MIDIControllerEvent.PropertyKey.numberKey] = event.number
                    newEvent[MIDIControllerEvent.PropertyKey.valueKey] = event.value
                    newEvent[MIDIControllerEvent.PropertyKey.dateKey] = event.date
                    events.append(newEvent)
                }
                newSession[JSONKey.midi_event] = events
            }
            
            sessions.append(newSession)
        }
        data[MotusLabFile.PropertyKey.sessionsKey] = sessions
        
        return data
    }
    
    
    /// Load MIDI controller events file
    ///
    /// - Parameter sessionId: The id of session
    /// - Returns: MIDI controller events
    func midiEvents(from sessionId: String) -> [MIDIControllerEvent]? {
        let midiFileUrl = self.fileURL.appendingPathComponent(FilePath.midi).appendingPathComponent(sessionId).appendingPathExtension(FileExtension.event)
        do {
            let data = try Data(contentsOf: midiFileUrl)
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? [MIDIControllerEvent]
        } catch let error as NSError {
            Swift.print("Export: midiEvents() Error openning url \(midiFileUrl), context: " + error.localizedDescription)
        }
        
        return nil
    }
    
    /// Convert console list of controllers [Bool] to list of enabled controllers [Int]
    ///
    /// - Parameter console: Array of Bool
    /// - Returns: Array of enabled controllers
    func convertConsoleController(_ console: [Bool]) -> [Int] {
        var result = [Int]()
        for n in 1..<console.count {
            if console[n] {
                result.append(n)
            }
        }
        return result
    }
    
}