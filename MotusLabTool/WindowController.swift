//
//  WindowController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    @objc dynamic var motusLabFile: MotusLabFile!
    var fileUrl: URL!
    var midiControllerEvents: [MIDIControllerEvent]!
    
    //MIDI Controllers
    @objc dynamic var consoleAParameters: MIDIParameters!
    @objc dynamic var consoleBParameters: MIDIParameters!
    var consoleAControllerColors = [Int: NSColor]()
    var consoleBControllerColors = [Int: NSColor]()
    
    @objc dynamic var displayedView: Int = 0
    @objc dynamic var showAcousmonium: NSButton.StateValue = .off
    
    var motusLabFileToSaveObservation: NSKeyValueObservation?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        Swift.print("WindowController > windowDidLoad")
        
        //Initialize user preferences
        self.loadPreferences()
        
        //Initializers
        self.consoleAParameters = MIDIParameters(console: 0, windowController: self)
        self.consoleBParameters = MIDIParameters(console: 1, windowController: self, enable: false)
        (self.contentViewController as! MainSplitViewController).initialization()
        
        //Add observer to detect preferences properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        let consoleBActivate = UserDefaults.standard.bool(forKey: PreferenceKey.consoleBActivate)
        if consoleBActivate != self.consoleBParameters.enable {
            self.consoleBParameters.enable = consoleBActivate
        }
        self.updateControllerColors()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let midiSettingsViewController = segue.destinationController as? MidiSettingsViewController {
            midiSettingsViewController.windowController = self
        }
    }
    
    //MARK: - Initializers
    
    /// Initialize user preferences
    func loadPreferences() {
        
        var preferences = [String: Any]()
        
        preferences[PreferenceKey.audioFormat] = 1 //0: AAC, 1: WAV
        preferences[PreferenceKey.consoleAColor] = NSColor.blue.data
        preferences[PreferenceKey.consoleBColor] = NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1).data
        preferences[PreferenceKey.consoleAMapping] = "1-25"
        preferences[PreferenceKey.consoleBMapping] = "1-25"
        preferences[PreferenceKey.consoleBActivate] = false
        preferences[PreferenceKey.switchPlayMode] = false
        
        preferences[PreferenceKey.playTimelineWaveform] = true
        preferences[PreferenceKey.playTimelineControllers] = true
        preferences[PreferenceKey.playTimelineMarkers] = true
        preferences[PreferenceKey.playTimelinePlayhead] = true
        preferences[PreferenceKey.playCTRLAlpha] = 0.8
        preferences[PreferenceKey.colorMode] = 0
        preferences[PreferenceKey.color1] = NSColor(calibratedRed: 0, green: 0.58, blue: 1, alpha: 1).data //light blue
        preferences[PreferenceKey.color2] = NSColor(calibratedRed: 1, green: 0.2, blue: 0, alpha: 1).data //red
        preferences[PreferenceKey.color3] = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0, alpha: 1).data //green
        preferences[PreferenceKey.color4] = NSColor(calibratedRed: 0.8, green: 0.4, blue: 1, alpha: 1).data //mauve
        preferences[PreferenceKey.color5] = NSColor(calibratedRed: 1, green: 0.58, blue: 0.2, alpha: 1).data //orange
        preferences[PreferenceKey.color6] = NSColor(calibratedRed: 0.6, green: 0, blue: 1, alpha: 1).data //purple
        preferences[PreferenceKey.color7] = NSColor(calibratedRed: 0.6, green: 0.4, blue: 0, alpha: 1).data //brown
        preferences[PreferenceKey.color8] = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1).data //grey
        preferences[PreferenceKey.playMarkerColor] = NSColor.black.data
        preferences[PreferenceKey.playPlayheadColor] = NSColor.red.data
        
        preferences[PreferenceKey.acousmoShowImage] = true
        preferences[PreferenceKey.acousmoOpacity] = 0.8
        preferences[PreferenceKey.acousmoSize] = 0.25
        preferences[PreferenceKey.acousmoShowTitles] = false
        
        preferences[PreferenceKey.valueCorrection] = 0 //0: None, 1: Yamaha02R96
        
        UserDefaults.standard.register(defaults: preferences)
        
    }
    
    func updateControllerColors() {
        Swift.print("WindowController > updateControllerColors")
        
        self.consoleAControllerColors.removeAll()
        self.consoleBControllerColors.removeAll()
        
        let preferences = UserDefaults.standard
        
        for n in 1..<129 {
            
            if self.consoleAParameters.filterControllers[n] {
                switch preferences.integer(forKey: PreferenceKey.colorMode) {
                case 0: //Consoles
                    self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color1)?.color
                case 1: //Groups of 8
                    if n < 9 {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color1)?.color
                    } else if n < 17 {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color2)?.color
                    } else if n < 25 {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color3)?.color
                    } else {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color4)?.color
                    }
                default:
                    break
                }
            }
            
            if self.consoleBParameters.filterControllers[n] {
                switch preferences.integer(forKey: PreferenceKey.colorMode) {
                case 0: //Consoles
                    self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color5)?.color
                case 1: //Groups of 8
                    if n < 9 {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color5)?.color
                    } else if n < 17 {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color6)?.color
                    } else if n < 25 {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color7)?.color
                    } else {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color8)?.color
                    }
                default:
                    break
                }
            }
        }
        
    }
    
    //MARK: - File read and save
    
    @IBAction func newDocument(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = [FileExtension.motuslab]
        savePanel.canCreateDirectories = true
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == .OK {
                if let url = savePanel.url {
                    self.fileUrl = url
                    self.createDocument()
                    self.setValue(1, forKey: "displayedView")
                }
            }
        }
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let selectFilePanel:NSOpenPanel = NSOpenPanel()
        selectFilePanel.allowsMultipleSelection = false
        selectFilePanel.canChooseDirectories = false
        selectFilePanel.canCreateDirectories = false
        selectFilePanel.canChooseFiles = true
        selectFilePanel.allowedFileTypes = [FileExtension.motuslab]
        
        selectFilePanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = selectFilePanel.urls.first {
                    do {
                        let data = try Data(contentsOf: url.appendingPathComponent(FilePath.motusLabFile).appendingPathExtension(FileExtension.data))
                        self.fileUrl = url
                        self.motusLabFile = NSKeyedUnarchiver.unarchiveObject(with: data) as? MotusLabFile
                        self.initializeMotusLabFileObserver()
                        self.setValue(2, forKey: "displayedView")
                    } catch let error as NSError {
                        Swift.print("WindowController: openDocument() Error openning url \(url), context: " + error.localizedDescription)
                    }
                    
                }
            }
        }
    }
    
    /// Create and save file in project
    func createDocument() {
        self.motusLabFile = MotusLabFile(name: self.fileUrl.fileName)
        self.midiControllerEvents = [MIDIControllerEvent]()
        self.createBundle()
        self.saveFile()
        self.initializeMotusLabFileObserver()
    }
    
    func initializeMotusLabFileObserver() {
        let toSavePath = \MotusLabFile.toSave
        self.motusLabFileToSaveObservation = self.motusLabFile.observe(toSavePath) { [unowned self] object, change in
            self.saveFile()
        }
    }
    
    /// Create folders
    func createBundle() {
        
        let audioUrl = self.fileUrl.appendingPathComponent(FilePath.audio)
        let movieUrl = self.fileUrl.appendingPathComponent(FilePath.movie)
        let midiUrl = self.fileUrl.appendingPathComponent(FilePath.midi)
        
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: self.fileUrl, withIntermediateDirectories: false, attributes: nil)
        } catch {
            Swift.print("WindowController: createBundle() Cannot copy bundle to url (" + self.fileUrl.path + ")!")
        }
        
        do {
            try fileManager.createDirectory(at: audioUrl, withIntermediateDirectories: false, attributes: nil)
        } catch {
            Swift.print("WindowController: createBundle() Cannot create audio subfolder!")
        }
        
        do {
            try fileManager.createDirectory(at: movieUrl, withIntermediateDirectories: false, attributes: nil)
        } catch {
            Swift.print("WindowController: createBundle() Cannot create movie subfolder!")
        }
        
        do {
            try fileManager.createDirectory(at: midiUrl, withIntermediateDirectories: false, attributes: nil)
        } catch {
            Swift.print("WindowController: createBundle() Cannot create midi subfolder!")
        }
        
    }
    
    /// Save motusLab file
    func saveFile() {
        
        if let motusLabFile = self.motusLabFile {
            let data:Data = NSKeyedArchiver.archivedData(withRootObject: motusLabFile)
            let dataUrl = self.fileUrl.appendingPathComponent(FilePath.motusLabFile).appendingPathExtension(FileExtension.data)
            do {
                try data.write(to: dataUrl)
            } catch let error as NSError {
                Swift.print("WindowController: save() Error saving data to url \(dataUrl), context: " + error.localizedDescription)
            }
        } else {
            Swift.print("WindowController: save() Cannot save project!")
        }
        
    }
    
    /// Save session MIDI events
    func saveMidi() {
        if let lastSession = self.motusLabFile.sessions.last {
            let url = self.fileUrl.appendingPathComponent(FilePath.midi).appendingPathComponent(lastSession.id).appendingPathExtension(FileExtension.event)
            let data:Data = NSKeyedArchiver.archivedData(withRootObject: self.midiControllerEvents as Any)
            do {
                try data.write(to: url)
            } catch let error as NSError {
                Swift.print("WindowController: saveMidi() Error writing file: " + error.localizedDescription)
            }
        } else {
            Swift.print("WindowController: saveMidi() Cannot access last recorded session!")
        }
    }
    
    //MARK: - Interface
    
    /// Update drawing of controllers in record mode
    func updateControllerView() {
        
    }
    
}
