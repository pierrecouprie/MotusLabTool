//
//  WindowController.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
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

class WindowController: NSWindowController {
    
    var appSupportFolder: URL!
    @objc dynamic var motusLabFile: MotusLabFile! {
        didSet {
            self.enableModeSegmentedControl()
        }
    }
    var fileUrl: URL!
    var midiControllerEvents: [MIDIControllerEvent]!
    var waitingWindowController: WaitingWindowController!
    
    // MIDI Controllers
    @objc dynamic var consoleAParameters: MIDIParameters!
    @objc dynamic var consoleBParameters: MIDIParameters!
    @objc dynamic var consoleCParameters: MIDIParameters!
    var consoleAControllerColors = [Int: NSColor]()
    var consoleBControllerColors = [Int: NSColor]()
    var consoleCControllerColors = [Int: NSColor]()
    
    //  Acousmoniums
    @objc dynamic var acousmoniumFiles = [AcousmoniumFile]()
    @objc dynamic weak var selectedAcousmoniumFile: AcousmoniumFile! {
        didSet {
            if self.selectedAcousmoniumFile != nil {
                let toSavePath = \AcousmoniumFile.toSave
                self.acousmoniumFileToSaveObservation = self.selectedAcousmoniumFile.observe(toSavePath) { [unowned self] object, change in
                    self.saveAcousmoniumFile(self.selectedAcousmoniumFile)
                }
            } else {
                self.acousmoniumFileToSaveObservation = nil
            }
        }
    }
    var acousmoniumFilesFolderPathUrl: URL!
    @objc dynamic var editAcousmonium = false
    
    // Playlist audio files
    var playlistFilesFolderPathUrl: URL!
    @objc dynamic var playlistFiles = [PlaylistFile]()
    @objc dynamic var playlistSelectedFileIndex: IndexSet! {
        didSet {
            if let leftViewController = self.leftViewController {
                leftViewController.initializePlaylistPlayer()
            }
        }
    }
    @objc dynamic var showBigCounter: Bool = false
    
    // Interface
    @objc dynamic var displayedView: Int = 0 {
        didSet {
            self.enableCommands()
        }
    }
    
    // MIDI
    @objc dynamic var enableSendMIDI = false
    
    @objc dynamic var enableModeToolbarButton = false
    @objc dynamic var enableRecordToolbarButtons = false //Add camera, record, Big counter
    @objc dynamic var enablePlayToolbarButtons = false //Controllers, midi playing, statistics
    @objc dynamic var enablePlayStopToolbarButtons = false //Play, stop
    @objc dynamic var showAcousmonium: NSButton.StateValue = .off
    @objc dynamic var toolbarRecord: NSButton.StateValue = .off {
        didSet {
            if self.toolbarRecord == .on {
                self.leftViewController.startRecording()
            } else {
                self.leftViewController.stopRecording()
            }
            self.enableCommands()
        }
    }
    @objc dynamic var toolbarPlay: NSButton.StateValue = .off
    @IBOutlet weak var modeSegmentedControl: NSSegmentedControl!
    @objc dynamic var currentMode: String = Mode.none {
        didSet {
            self.enableModeSegmentedControl()
        }
    }
    
    @IBOutlet weak var counterButton: NSButtonCounter!
    @objc dynamic var timePosition: Float = 0 {
        didSet {
            self.counterButton.counterValue = self.timePosition
        }
    }
    
    var motusLabFileToSaveObservation: NSKeyValueObservation?
    var acousmoniumFileToSaveObservation: NSKeyValueObservation?
    
    // Alias
    @objc dynamic weak var leftViewController: LeftViewController! {
        return (self.contentViewController as! MainSplitViewController).splitViewItems[0].viewController as? LeftViewController
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Initializers
        self.loadPreferences()
        self.initializeAcousmonium()
        self.loadAcousmoniums()
        self.initializeWaveformPlaylist()
        self.loadPlaylistFiles()
        self.consoleAParameters = MIDIParameters(console: 0, windowController: self)
        self.consoleAParameters.filter = UserDefaults.standard.string(forKey: PreferenceKey.consoleAMapping)!
        self.consoleBParameters = MIDIParameters(console: 1, windowController: self, enable: false)
        self.consoleBParameters.filter = UserDefaults.standard.string(forKey: PreferenceKey.consoleBMapping)!
        self.consoleCParameters = MIDIParameters(console: 2, windowController: self, enable: false)
        self.consoleCParameters.filter = UserDefaults.standard.string(forKey: PreferenceKey.consoleCMapping)!
        (self.contentViewController as! MainSplitViewController).initialization()
        
        // Add observer to detect changes in preference properties
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Preference properties changes
    @objc func userDefaultsDidChange(_ notification: Notification) {
        if let consoleBParameters = self.consoleBParameters, let consoleCParameters = self.consoleCParameters {
            let consoleBActivate = UserDefaults.standard.bool(forKey: PreferenceKey.consoleBActivate)
            if consoleBActivate != consoleBParameters.enable {
                consoleBParameters.enable = consoleBActivate
            }
            let consoleCActivate = UserDefaults.standard.bool(forKey: PreferenceKey.consoleCActivate)
            if consoleCActivate != consoleCParameters.enable {
                consoleCParameters.enable = consoleCActivate
            }
            self.updateControllerColors()
        }
        self.enableCommands()
    }
    
    /// Open sheet windows
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let midiSettingsViewController = segue.destinationController as? MidiSettingsViewController {
            midiSettingsViewController.windowController = self
        } else if let playlistViewController = segue.destinationController as? PlaylistViewController {
            playlistViewController.windowController = self
        }
    }
    
    func enableCommands() {
        switch self.displayedView {
        case 0: // Session
            self.setValue(false, forKey: "enableRecordToolbarButtons")
            self.setValue(false, forKey: "enablePlayToolbarButtons")
            self.setValue(false, forKey: "enablePlayStopToolbarButtons")
        case 1: // Record
            if UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist) {
                self.setValue(true, forKey: "enableRecordToolbarButtons")
                if self.currentMode == Mode.none {
                    self.setValue(true, forKey: "enablePlayStopToolbarButtons")
                } else {
                    self.setValue(false, forKey: "enablePlayStopToolbarButtons")
                }
            } else {
                self.setValue(true, forKey: "enableRecordToolbarButtons")
                self.setValue(false, forKey: "enablePlayStopToolbarButtons")
            }
            self.setValue(false, forKey: "enablePlayToolbarButtons")
        case 2: // Play
            self.setValue(false, forKey: "enableRecordToolbarButtons")
            self.setValue(true, forKey: "enablePlayToolbarButtons")
            self.setValue(true, forKey: "enablePlayStopToolbarButtons")
        default:
            break
        }
    }
    
    func enableModeSegmentedControl() {
        switch self.currentMode {
        case Mode.none :
            self.modeSegmentedControl.setEnabled(true, forSegment: 0)
            self.modeSegmentedControl.setEnabled(true, forSegment: 1)
            if self.motusLabFile != nil && self.motusLabFile.sessions.count > 0 {
                self.modeSegmentedControl.setEnabled(true, forSegment: 2)
            } else {
                self.modeSegmentedControl.setEnabled(false, forSegment: 2)
            }
            if self.toolbarPlay == .on {
                self.setValue(NSButton.StateValue.off, forKey: "toolbarPlay")
            }
        case Mode.recording :
            self.modeSegmentedControl.setEnabled(true, forSegment: 0)
            self.modeSegmentedControl.setEnabled(true, forSegment: 1)
            self.modeSegmentedControl.setEnabled(false, forSegment: 2)
        case Mode.playing :
            self.modeSegmentedControl.setEnabled(true, forSegment: 0)
            self.modeSegmentedControl.setEnabled(false, forSegment: 1)
            self.modeSegmentedControl.setEnabled(true, forSegment: 2)
        default:
            break
        }
    }
    
    //MARK: - Initializers
    
    /// Initialize user preferences
    func loadPreferences() {
        
        var preferences = [String: Any]()
        
        preferences[PreferenceKey.audioFormat] = 1 //0: AAC, 1: WAV
        preferences[PreferenceKey.consoleAColor] = NSColor.blue.data //blue
        preferences[PreferenceKey.consoleBColor] = NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1).data //green
        preferences[PreferenceKey.consoleCColor] = NSColor(calibratedRed: 1, green: 0.58, blue: 0.2, alpha: 1).data //orange
        preferences[PreferenceKey.consoleAMapping] = "1-25"
        preferences[PreferenceKey.consoleBMapping] = "1-25"
        preferences[PreferenceKey.consoleCMapping] = "1-25"
        preferences[PreferenceKey.consoleBActivate] = false
        preferences[PreferenceKey.consoleCActivate] = false
        preferences[PreferenceKey.switchPlayMode] = false
        preferences[PreferenceKey.bitDepth] = 16
        preferences[PreferenceKey.sampleRate] = 44100
        preferences[PreferenceKey.channelNumber] = 2
        
        //preferences[PreferenceKey.movieSync] = true // Obsolete in 2.3
        preferences[PreferenceKey.movieSync2] = 1 // 2.3
        preferences[PreferenceKey.moviePredelay] = 0.7
        
        preferences[PreferenceKey.movieSize] = 1 // 960 x 540
        preferences[PreferenceKey.movieQuality] = 2 // High
        
        preferences[PreferenceKey.playTimelineWaveform] = true
        preferences[PreferenceKey.playTimelineControllers] = true
        preferences[PreferenceKey.playTimelineMarkers] = true
        preferences[PreferenceKey.playTimelinePlayhead] = true
        preferences[PreferenceKey.playCTRLAlpha] = 0.8
        //preferences[PreferenceKey.colorMode] = 0
        preferences[PreferenceKey.color1] = NSColor(calibratedRed: 0, green: 0.58, blue: 1, alpha: 1).data //light blue
        preferences[PreferenceKey.color1Num] = 7
        preferences[PreferenceKey.color2] = NSColor(calibratedRed: 1, green: 0.2, blue: 0, alpha: 1).data //red
        preferences[PreferenceKey.color2Num] = 7
        preferences[PreferenceKey.color3] = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0, alpha: 1).data //green
        preferences[PreferenceKey.color3Num] = 7
        preferences[PreferenceKey.color4] = NSColor(calibratedRed: 0.8, green: 0.4, blue: 1, alpha: 1).data //mauve
        preferences[PreferenceKey.color5] = NSColor(calibratedRed: 1, green: 0.58, blue: 0.2, alpha: 1).data //orange
        preferences[PreferenceKey.color5Num] = 7
        preferences[PreferenceKey.color6] = NSColor(calibratedRed: 0.6, green: 0, blue: 1, alpha: 1).data //purple
        preferences[PreferenceKey.color6Num] = 7
        preferences[PreferenceKey.color7] = NSColor(calibratedRed: 0.6, green: 0.4, blue: 0, alpha: 1).data //brown
        preferences[PreferenceKey.color7Num] = 7
        preferences[PreferenceKey.color8] = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1).data //grey
        preferences[PreferenceKey.color9] = NSColor(calibratedRed: 0.99, green: 0.70, blue: 0.11, alpha: 1.0).data //cantaloupe
        preferences[PreferenceKey.color9Num] = 7
        preferences[PreferenceKey.color10] = NSColor(calibratedRed: 0.06, green: 0.42, blue: 0.03, alpha: 1.0).data //dark green
        preferences[PreferenceKey.color10Num] = 7
        preferences[PreferenceKey.color11] = NSColor(calibratedRed: 0.45, green: 0.55, blue: 0.05, alpha: 1.0).data //olive
        preferences[PreferenceKey.color11Num] = 7
        preferences[PreferenceKey.color12] = NSColor(calibratedRed: 0.34, green: 0.16, blue: 0.53, alpha: 1.0).data //dark purple
        preferences[PreferenceKey.playMarkerColor] = NSColor.black.data
        preferences[PreferenceKey.playPlayheadColor] = NSColor.red.data
        
        preferences[PreferenceKey.acousmoShowImage] = true
        preferences[PreferenceKey.acousmoOpacity] = 0.8
        preferences[PreferenceKey.acousmoSize] = 0.25
        preferences[PreferenceKey.acousmoShowTitles] = false
        
        preferences[PreferenceKey.statisticsShow] = false
        preferences[PreferenceKey.statisticsMin] = true
        preferences[PreferenceKey.statisticsMax] = true
        preferences[PreferenceKey.statisticsAMean] = true
        preferences[PreferenceKey.statisticsQMean] = false
        preferences[PreferenceKey.statisticsVariance] = false
        preferences[PreferenceKey.statisticsFrequency] = false
        preferences[PreferenceKey.statisticsDuration] = false
        
        preferences[PreferenceKey.valueCorrection] = 0 //0: None, 1: Yamaha02R96
        preferences[PreferenceKey.usePlaylist] = false
        
        UserDefaults.standard.register(defaults: preferences)
        
    }
    
    /// Update the color of controllers (saved in consoleAControllerColors and consoleBControllerColors)
    func updateControllerColors() {
        
        if let consoleAParameters = self.consoleAParameters, let consoleBParameters = self.consoleBParameters, let consoleCParameters = self.consoleCParameters {
            
            self.consoleAControllerColors.removeAll()
            self.consoleBControllerColors.removeAll()
            self.consoleCControllerColors.removeAll()
            
            let preferences = UserDefaults.standard
            
            /*var consoleAIndex: Int = 1
            var consoleBIndex: Int = 1
            var consoleCIndex: Int = 1*/
            for n in 1..<129 {
                
                if consoleAParameters.filterControllers[n] {
                    
                    let num1 = preferences.integer(forKey: PreferenceKey.color1Num) + 1
                    let num2 = preferences.integer(forKey: PreferenceKey.color2Num) + 1
                    let num3 = preferences.integer(forKey: PreferenceKey.color3Num) + 1
                    
                    if n <= num1 {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color1)?.color
                    } else if n <= num1 + num2 {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color2)?.color
                    } else if n <= num1 + num2 + num3 {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color3)?.color
                    } else {
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color4)?.color
                    }
                    
                }
                
                if consoleBParameters.filterControllers[n] {
                    
                    let num1 = preferences.integer(forKey: PreferenceKey.color5Num) + 1
                    let num2 = preferences.integer(forKey: PreferenceKey.color6Num) + 1
                    let num3 = preferences.integer(forKey: PreferenceKey.color7Num) + 1
                    
                    if n <= num1 {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color5)?.color
                    } else if n <= num1 + num2 {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color6)?.color
                    } else if n <= num1 + num2 + num3 {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color7)?.color
                    } else {
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color8)?.color
                    }
                    
                }
                
                if consoleCParameters.filterControllers[n] {
                    
                    let num1 = preferences.integer(forKey: PreferenceKey.color9Num) + 1
                    let num2 = preferences.integer(forKey: PreferenceKey.color10Num) + 1
                    let num3 = preferences.integer(forKey: PreferenceKey.color11Num) + 1
                    
                    if n <= num1 {
                        self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color9)?.color
                    } else if n <= num1 + num2 {
                        self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color10)?.color
                    } else if n <= num1 + num2 + num3 {
                        self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color11)?.color
                    } else {
                        self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color12)?.color
                    }
                    
                }
                
                /*if consoleAParameters.filterControllers[n] {
                    switch preferences.integer(forKey: PreferenceKey.colorMode) {
                    case 0: // Consoles
                        self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color1)?.color
                    case 1: // Groups of 8
                        if consoleAIndex < 9 {
                            self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color1)?.color
                        } else if consoleAIndex < 17 {
                            self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color2)?.color
                        } else if consoleAIndex < 25 {
                            self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color3)?.color
                        } else {
                            self.consoleAControllerColors[n] = preferences.data(forKey: PreferenceKey.color4)?.color
                        }
                        consoleAIndex += 1
                    default:
                        break
                    }
                }
                
                if consoleBParameters.filterControllers[n] {
                    switch preferences.integer(forKey: PreferenceKey.colorMode) {
                    case 0: // Consoles
                        self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color5)?.color
                    case 1: // Groups of 8
                        if consoleBIndex < 9 {
                            self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color5)?.color
                        } else if consoleBIndex < 17 {
                            self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color6)?.color
                        } else if consoleBIndex < 25 {
                            self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color7)?.color
                        } else {
                            self.consoleBControllerColors[n] = preferences.data(forKey: PreferenceKey.color8)?.color
                        }
                        consoleBIndex += 1
                    default:
                        break
                    }
                }
                
                if consoleCParameters.filterControllers[n] {
                    switch preferences.integer(forKey: PreferenceKey.colorMode) {
                    case 0: // Consoles
                        self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color9)?.color
                    case 1: // Groups of 8
                        if consoleCIndex < 9 {
                            self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color9)?.color
                        } else if consoleCIndex < 17 {
                            self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color10)?.color
                        } else if consoleCIndex < 25 {
                            self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color11)?.color
                        } else {
                            self.consoleCControllerColors[n] = preferences.data(forKey: PreferenceKey.color12)?.color
                        }
                        consoleCIndex += 1
                    default:
                        break
                    }
                }*/
                
            }
            
        }
        
    }
    
    /// Initialize URL of acousmonium folder (Library > App Support > motuLab > acousmoniums)
    func initializeAcousmonium() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        self.appSupportFolder = URL(fileURLWithPath: paths[0]).appendingPathComponent(FilePath.motuLab)
        self.acousmoniumFilesFolderPathUrl = self.appSupportFolder.appendingPathComponent(FilePath.acousmoniums)
    }
    
    /// Initialize URL for waveform folder used with playlist (Library > Application Support > motuLab > waveforms)
    func initializeWaveformPlaylist() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        self.appSupportFolder = URL(fileURLWithPath: paths[0]).appendingPathComponent(FilePath.motuLab)
        self.playlistFilesFolderPathUrl = self.appSupportFolder.appendingPathComponent(FilePath.waveforms)
    }
    
    //MARK: - File read and save
    
    /// Create a new document
    @IBAction func newDocument(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = [FileExtension.motuslab]
        savePanel.canCreateDirectories = true
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == .OK {
                if let url = savePanel.url {
                    self.fileUrl = url
                    self.createDocument()
                    
                    // Switch to record tabview page
                    self.setValue(1, forKey: "displayedView")
                    
                    // Enable toolbar items
                    self.setValue(true, forKey: "enableModeToolbarButton")
                }
            }
        }
    }
    
    /// Open a document
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
                    self.openMotusLabFile(url)
                }
            }
        }
    }
    
    /// Load the opened file
    /// This part is detached to previous func to respond to application() in App Delegate
    func openMotusLabFile(_ url: URL) {
        do {
            //Load motusLab file
            let data = try Data(contentsOf: url.appendingPathComponent(FilePath.motusLabFile).appendingPathExtension(FileExtension.data))
            self.fileUrl = url
            self.motusLabFile = NSKeyedUnarchiver.unarchiveObject(with: data) as? MotusLabFile
            
            //Activate toolbar mode button
            self.setValue(true, forKey: "enableModeToolbarButton")
            
            //Select first session
            self.leftViewController.selectedSessionIndex = IndexSet(integer: 0)
            
            //Switch to play tabView page
            self.setValue(2, forKey: "displayedView")
            
        } catch let error as NSError {
            Swift.print("WindowController: openMotusLabFile() Error openning url \(url), context: " + error.localizedDescription)
        }
    }
    
    /// Create a new document
    func createDocument() {
        self.motusLabFile = MotusLabFile(name: self.fileUrl.fileName)
        self.midiControllerEvents = [MIDIControllerEvent]()
        self.createBundle(at: self.fileUrl)
        self.saveFile()
        self.initializeMotusLabFileObserver()
    }
    
    /// Initialize observer whcih manage saving of file
    func initializeMotusLabFileObserver() {
        let toSavePath = \MotusLabFile.toSave
        self.motusLabFileToSaveObservation = self.motusLabFile.observe(toSavePath) { [unowned self] object, change in
            self.saveFile()
        }
    }
    
    /// Create folders of new document bundle
    ///
    /// newProject.motusLab (bundle)
    ///   |- audio  (folder)
    ///   |- midi   (folder)
    ///   |- movie  (folder)
    func createBundle(at url: URL) {
        
        let audioUrl = url.appendingPathComponent(FilePath.audio)
        let movieUrl = url.appendingPathComponent(FilePath.movie)
        let midiUrl = url.appendingPathComponent(FilePath.midi)
        
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
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
    
    /// Save .motusLab file in project bundle
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
    
    /// Save session MIDI events (midi folder)
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
    
    //MARK: - Read and save acousmonium files
    
    /// Load acousmonium files from library > Application Support > motusLab > acousmoniums
    func loadAcousmoniums() {
        
        let fileManager = FileManager.default
        
        // Create acousmoniums folder if does not exist
        if !fileManager.fileExists(atPath: self.acousmoniumFilesFolderPathUrl.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: self.acousmoniumFilesFolderPathUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Swift.print("WindowController: loadAcousmoniums() Cannot copy bundle to url (" + self.fileUrl.path + ")!")
            }
        }
        
        // Read acousmonium files
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: self.acousmoniumFilesFolderPathUrl, includingPropertiesForKeys: nil)
            for file in fileURLs {
                do {
                    let acousmoniumData = try Data(contentsOf: file)
                    if let acousmonium = NSKeyedUnarchiver.unarchiveObject(with: acousmoniumData) as? AcousmoniumFile {
                        self.acousmoniumFiles.append(acousmonium)
                    }
                } catch let error as NSError {
                    Swift.print("WindowController: loadAcousmoniums() Error openning url \(file), context: " + error.localizedDescription)
                }
            }
        } catch {
            print("WindowController: loadAcousmoniums Error while enumerating files \(self.acousmoniumFilesFolderPathUrl.path): \(error.localizedDescription)")
        }
        
    }
    
    
    /// Create a new acousmonium file (used from properties of acousmonium window)
    /// - Parameter name: Name of the new acousmonium (untitled)
    func createAcousmoniumFile(_ name: String) {
        var acousmoniumFiles = self.acousmoniumFiles
        let newAcousmoniumFile = AcousmoniumFile(name: name)
        acousmoniumFiles.append(newAcousmoniumFile)
        self.setValue(acousmoniumFiles, forKey: "acousmoniumFiles")
        self.setValue(newAcousmoniumFile, forKey: "selectedAcousmoniumFile")
        self.saveAcousmoniumFile(newAcousmoniumFile)
    }
    
    func deleteAcousmoniumFile(_ acousmoniumFile: AcousmoniumFile) {
        var acousmoniumFiles = self.acousmoniumFiles
        for (index,acousmonium) in acousmoniumFiles.enumerated() {
            if acousmonium == acousmoniumFile {
                let fileUrl = self.appSupportFolder.appendingPathComponent(FilePath.acousmoniums).appendingPathComponent(acousmoniumFile.id).appendingPathExtension(FileExtension.acousmonium)
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteAcousmoniumFile() Error deleting acousmonium to url \(fileUrl), context: " + error.localizedDescription)
                }
                
                acousmoniumFiles.remove(at: index)
                break
            }
        }
        self.setValue(acousmoniumFiles, forKey: "acousmoniumFiles")
        self.setValue(nil, forKey: "selectedAcousmoniumFile")
    }
    
    /// Save parameters of selected acousmonium
    /// - Parameter acousmoniumFile: The name of the acousmonium
    func saveAcousmoniumFile(_ acousmoniumFile: AcousmoniumFile) {
        let acousmoniumData:Data = NSKeyedArchiver.archivedData(withRootObject: acousmoniumFile)
        let fileUrl = self.appSupportFolder.appendingPathComponent(FilePath.acousmoniums).appendingPathComponent(acousmoniumFile.id).appendingPathExtension(FileExtension.acousmonium)
        do {
            try acousmoniumData.write(to: fileUrl)
        } catch let error as NSError {
            Swift.print("WindowController: saveAcousmoniumFile() Error saving data to url \(fileUrl), context: " + error.localizedDescription)
        }
    }
    
    //MARK: - Read and save playlist
    
    /// Load list of playlist URLs
    func loadPlaylistFiles() {
        
        let fileManager = FileManager.default
        
        // Create waveform folder if it does not exist
        if !fileManager.fileExists(atPath: self.playlistFilesFolderPathUrl.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: self.playlistFilesFolderPathUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Swift.print("WindowController: loadPlaylistFiles() Cannot copy bundle to url (" + self.fileUrl.path + ")!")
            }
        }
        
        // Read playlist file (list of URLs)
        let playlistFileURL = self.appSupportFolder.appendingPathComponent(FilePath.playlist).appendingPathExtension(FileExtension.data)
        do {
            let playlistData = try Data(contentsOf: playlistFileURL)
            if let playlist = NSKeyedUnarchiver.unarchiveObject(with: playlistData) as? [PlaylistFile] {
                
                // Load playlist
                self.playlistFiles = playlist
                
                // Delete references to files which are not available in disk
                var changed = false
                for n in stride(from: self.playlistFiles.count-1, through: 0, by: -1) {
                    if !FileManager.default.fileExists(atPath: self.playlistFiles[n].url!.path) {
                        self.playlistFiles.remove(at: n)
                        changed =  true
                    }
                }
                if changed {
                    self.saveFile()
                }
                
                //Select first item
                if self.playlistFiles.count > 0 {
                    self.setValue(IndexSet(integer: 0), forKey: "playlistSelectedFileIndex")
                }
            }
        } catch let error as NSError {
            Swift.print("ViewController: loadPlaylistFiles() Error openning url \(playlistFileURL), context: " + error.localizedDescription)
        }

    }
    
    /// Add new file(s) in playlist
    /// - Parameter urls: One or several URLs in an Array
    func addPlaylistFiles(_ urls: [URL], playlistViewController: PlaylistViewController) {
        var playlistFiles = self.playlistFiles
        playlistViewController.setValue(true, forKey: "showImportingLabel")
        
        let queue = DispatchQueue(label: "com.pierrecouprie.motusLabTool.importFile", qos: .utility, attributes: .concurrent)
        queue.async {
            
            DispatchQueue.concurrentPerform(iterations: urls.count) {
                index in
                
                let url = urls[index]
                let id = UUID().uuidString
                let folderURL = url.deletingPathExtension().deletingLastPathComponent()
                let name = url.fileName
                let audioAnalyzer = AudioAnalyzer(url)
                if let waveform = audioAnalyzer.computeChannelsData() {
                    let playlistFile = PlaylistFile(url: url, folderURL: folderURL, id: id, name: name, duration: audioAnalyzer.duration)
                    let waveformData:Data = NSKeyedArchiver.archivedData(withRootObject: waveform)
                    let waveformURL = self.playlistFilesFolderPathUrl.appendingPathComponent(id).appendingPathExtension(FileExtension.waveform)
                    do {
                        try waveformData.write(to: waveformURL)
                        playlistFiles.append(playlistFile)
                    } catch let error as NSError {
                        DispatchQueue.main.async {
                            Swift.print("WindowController: savePlaylist() Error saving data to url \(String(describing: self.fileUrl)), context: " + error.localizedDescription)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        Swift.print("WindowController: addPlaylistFiles() Error computing waveform from file \(url)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.setValue(playlistFiles, forKey: "playlistFiles")
                self.savePlaylist()
                playlistViewController.setValue(false, forKey: "showImportingLabel")
            }
            
        }
    }
    
    /// Delete selected playlist item
    func removeSelectedFiles() {
        if let playlistSelectedFileIndex = self.playlistSelectedFileIndex, let playlistFilesFolderPathUrl = self.playlistFilesFolderPathUrl {
            let fileManager = FileManager.default
            var playlistFiles = self.playlistFiles
            let fileCount = playlistFiles.count
            for n in stride(from: fileCount - 1, through: 0, by: -1) {
                if playlistSelectedFileIndex.contains(n) {
                    let waveformURL = playlistFilesFolderPathUrl.appendingPathComponent(playlistFiles[n].id).appendingPathExtension(FileExtension.waveform)
                    do {
                        try fileManager.removeItem(at: waveformURL)
                    } catch let error as NSError {
                        Swift.print("WindowController: removeSelectedFiles() Error deleting waveform to url \(String(describing: waveformURL)), context: " + error.localizedDescription)
                    }
                    playlistFiles.remove(at: n)
                }
            }
            self.setValue(playlistFiles, forKey: "playlistFiles")
            self.savePlaylist()
        }
    }
    
    /// Save the playlist file (Library > Application Support > motusLab > playlist.data)
    func savePlaylist() {
        let playlistData:Data = NSKeyedArchiver.archivedData(withRootObject: self.playlistFiles)
        let fileUrl = self.appSupportFolder.appendingPathComponent(FilePath.playlist).appendingPathExtension(FileExtension.data)
        do {
            try playlistData.write(to: fileUrl)
        } catch let error as NSError {
            Swift.print("WindowController: savePlaylist() Error saving data to url \(fileUrl), context: " + error.localizedDescription)
        }
    }
    
    //MARK: - Waiting window
    
    func openWaitingWindow(with information: String, maxValue: Double? = nil) {
        if self.waitingWindowController == nil {
            self.waitingWindowController = WaitingWindowController(windowNibName: "WaitingWindow")
        }
        self.window!.beginSheet(self.waitingWindowController.window!, completionHandler: nil)
        if let max = maxValue {
            self.waitingWindowController.progressIndicator.isIndeterminate = false
            self.waitingWindowController.progressIndicator.maxValue = max
        } else {
            self.waitingWindowController.progressIndicator.isIndeterminate = true
        }
        self.waitingWindowController.progressIndicator.usesThreadedAnimation = true
        self.waitingWindowController.progressIndicator.startAnimation(self)
        self.waitingWindowController.information.stringValue = information
    }
    
    func increaseWaitingWindowProgressIndicator() {
        guard self.waitingWindowController != nil else {
            return
        }
        self.waitingWindowController.progressIndicator.doubleValue += 1
    }
    
    func closeWaitingWindow() {
        guard self.waitingWindowController != nil && self.waitingWindowController.window!.isVisible else {
            return
        }
        self.window!.endSheet(self.waitingWindowController.window!)
    }
    
    //MARK: - Toolbar
    
    @IBAction func play(_ sender: Any) {
        if (sender as! NSButton).state == .on {
            if self.displayedView == 2 {
                self.leftViewController.startPlaying()
            } else {
                self.leftViewController.startPlayingPlaylist()
            }
        } else {
            if self.displayedView == 2 {
                self.leftViewController.stopPlaying(pause: true)
            } else {
                self.leftViewController.pausePlayingPlaylist()
            }
        }
    }
    
    @IBAction func stop(_ sender: Any) {
        if self.displayedView == 2 {
            self.leftViewController.stopPlaying()
        } else {
           self.leftViewController.stopPlayingPlaylist()
        }
    }
    
    @IBAction func showBlackWindow(_ sender: Any) {
        let contentView = self.window?.contentView
        if (sender as! NSButton).state == .on {
            let blackWindow = BlackView(frame: contentView!.bounds)
            contentView?.addSubview(blackWindow)
            blackWindow.addInViewConstraints(superView: contentView!)
        } else {
            if contentView!.subviews.count > 0 {
                contentView!.subviews.last!.removeFromSuperview()
            }
        }
    }
    
    @IBAction func addCamera(_ sender: Any) {
        self.leftViewController.addCamera()
    }
    
    /// Manage which controllers is drowing in timeline (play nmode)
    @IBAction func showControllers(_ sender: Any) {
        self.leftViewController.showControllersMenu(sender)
    }
    
    /// Manage which controllers send MIDI message to external mix console (play mode)
    @IBAction func showMidiPlayMenu(_ sender: Any) {
        self.leftViewController.showMidiPlayMenu(sender)
    }
    
    //MARK: - Menus
    
    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        if let action = menuItem.action {
            
            if action == #selector(self.changeMidiPlayMenu(_:)) {
                if self.leftViewController.controllersList[menuItem.tag].enable {
                    menuItem.state = .on
                } else {
                    menuItem.state = .off
                }
            }
            
            if action == #selector(self.export(_:)) {
                if self.motusLabFile == nil {
                    return false
                }
            }
            
            if action == #selector(self.exportAcousmonium(_:)) {
                if self.selectedAcousmoniumFile == nil {
                    return false
                }
            }
            
            if action == #selector(self.deleteCurrentSession(_:)) {
                if self.motusLabFile == nil {
                    return false
                } else {
                    if self.motusLabFile.sessions.count == 0 || self.displayedView != 0 {
                        return false
                    }
                }
            }
            
            if action == #selector(self.exportSelectedSession(_:)) {
                if self.motusLabFile == nil {
                    return false
                } else {
                    if self.motusLabFile.sessions.count == 0 || self.displayedView != 0 {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    @IBAction func export(_ sender: Any) {
        let exportPanel = NSSavePanel()
        exportPanel.canCreateDirectories = true
        exportPanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == .OK {
                if let url = exportPanel.url {
                    self.openWaitingWindow(with: "Exporting...")
                    let export = Export(url, fileURL: self.fileUrl, motusLabFile: self.motusLabFile)
                    let queue = DispatchQueue(label: "com.pierrecouprie.motuslabTool.export", qos: .background, attributes: .concurrent)
                    queue.async() {
                        export.export()
                        DispatchQueue.main.async {
                            self.closeWaitingWindow()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func exportSelectedSession(_ sender: Any) {
        if let firstIndex = self.leftViewController.selectedSessionIndex.first {
            let exportPanel = NSSavePanel()
            exportPanel.canCreateDirectories = true
            exportPanel.allowedFileTypes = [FileExtension.motuslab]
            exportPanel.begin { (result: NSApplication.ModalResponse) -> Void in
                if result == .OK {
                    
                    let fileManager = FileManager.default
                    let session = self.motusLabFile.sessions[firstIndex]
                    
                    //Create bundle structure
                    self.createBundle(at: exportPanel.url!)
                    
                    //Copy audio file
                    var inputUrl = self.fileUrl.appendingPathComponent(FilePath.audio).appendingPathComponent(session.id).appendingPathExtension(session.audioFormat)
                    var outputUrl = exportPanel.url!.appendingPathComponent(FilePath.audio).appendingPathComponent(session.id).appendingPathExtension(session.audioFormat)
                    do {
                        try fileManager.copyItem(at: inputUrl, to: outputUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error copying file in url \(inputUrl) ot url \(outputUrl), context: " + error.localizedDescription)
                    }
                    
                    //Copy Video files
                    inputUrl = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.A).appendingPathExtension(FileExtension.mp4)
                    outputUrl = exportPanel.url!.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.A).appendingPathExtension(FileExtension.mp4)
                    do {
                        try fileManager.copyItem(at: inputUrl, to: outputUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error copying file in url \(inputUrl) ot url \(outputUrl), context: " + error.localizedDescription)
                    }
                    
                    inputUrl = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.B).appendingPathExtension(FileExtension.mp4)
                    outputUrl = exportPanel.url!.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.B).appendingPathExtension(FileExtension.mp4)
                    do {
                        try fileManager.copyItem(at: inputUrl, to: outputUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error copying file in url \(inputUrl) ot url \(outputUrl), context: " + error.localizedDescription)
                    }
                    
                    inputUrl = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.C).appendingPathExtension(FileExtension.mp4)
                    outputUrl = exportPanel.url!.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.C).appendingPathExtension(FileExtension.mp4)
                    do {
                        try fileManager.copyItem(at: inputUrl, to: outputUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error copying file in url \(inputUrl) ot url \(outputUrl), context: " + error.localizedDescription)
                    }
                    
                    inputUrl = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.D).appendingPathExtension(FileExtension.mp4)
                    outputUrl = exportPanel.url!.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.D).appendingPathExtension(FileExtension.mp4)
                    do {
                        try fileManager.copyItem(at: inputUrl, to: outputUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error copying file in url \(inputUrl) ot url \(outputUrl), context: " + error.localizedDescription)
                    }
                    
                    //Copy event file
                    inputUrl = self.fileUrl.appendingPathComponent(FilePath.midi).appendingPathComponent(session.id).appendingPathExtension(FileExtension.event)
                    outputUrl = exportPanel.url!.appendingPathComponent(FilePath.midi).appendingPathComponent(session.id).appendingPathExtension(FileExtension.event)
                    do {
                        try fileManager.copyItem(at: inputUrl, to: outputUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error copying file in url \(inputUrl) ot url \(outputUrl), context: " + error.localizedDescription)
                    }
                    
                    //Create data file
                    let file = self.motusLabFile.copy() as! MotusLabFile
                    file.sessions.removeAll()
                    file.sessions.append(session.copy() as! Session)
                    let data:Data = NSKeyedArchiver.archivedData(withRootObject: file)
                    let dataUrl = exportPanel.url!.appendingPathComponent(FilePath.motusLabFile).appendingPathExtension(FileExtension.data)
                    do {
                        try data.write(to: dataUrl)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportSelectedSession() Error saving data to url \(dataUrl), context: " + error.localizedDescription)
                    }
                    
                }
            }
        }
    }
    
    @IBAction func exportAcousmonium(_ sender: Any) {
        let exportPanel = NSSavePanel()
        exportPanel.canCreateDirectories = true
        exportPanel.allowedFileTypes = [FileExtension.acousmonium]
        exportPanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == .OK {
                if let url = exportPanel.url, let selectedAcousmoniumFile = self.selectedAcousmoniumFile {
                    
                    let acousmoniumData:Data = NSKeyedArchiver.archivedData(withRootObject: selectedAcousmoniumFile)
                    do {
                        try acousmoniumData.write(to: url)
                    } catch let error as NSError {
                        Swift.print("WindowController: exportAcousmonium() Error saving acousmonium to url \(url), context: " + error.localizedDescription)
                    }
                    
                }
            }
        }
    }
    
    /// Import an acousmonium file (.acousmonium)
    @IBAction func importAcousmonium(_ sender: Any) {
        let selectAcousmoniumPanel:NSOpenPanel = NSOpenPanel()
        selectAcousmoniumPanel.allowsMultipleSelection = true
        selectAcousmoniumPanel.canChooseDirectories = false
        selectAcousmoniumPanel.canCreateDirectories = false
        selectAcousmoniumPanel.canChooseFiles = true
        selectAcousmoniumPanel.allowedFileTypes = [FileExtension.acousmonium]
        
        selectAcousmoniumPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                for url in selectAcousmoniumPanel.urls {
                    self.importAcousmoniumFile(url)
                }
            }
        }
    }
    
    /// Load the opened acousmonium file
    /// This part is detached to previous func to respond to application() in App Delegate
    func importAcousmoniumFile(_ url: URL) {
        do {
            var acousmFiles = self.acousmoniumFiles
            let data = try Data(contentsOf: url)
            let acousmoniumFile = NSKeyedUnarchiver.unarchiveObject(with: data) as! AcousmoniumFile
            acousmFiles.append(acousmoniumFile)
            self.saveAcousmoniumFile(acousmoniumFile)
            self.setValue(acousmFiles, forKey: "acousmoniumFiles")
        } catch let error as NSError {
            Swift.print("WindowController: importAcousmoniumFile() Error importing acousmonium from url \(url), context: " + error.localizedDescription)
        }
    }
    
    @IBAction func deleteCurrentSession(_ sender: Any) {
        let a = NSAlert()
        a.messageText = "Delete current session"
        a.informativeText = "Are you sure you want to delete the selected session? This action cannot be undone!"
        a.addButton(withTitle: "Delete")
        a.addButton(withTitle: "Cancel")
        a.alertStyle = .warning
        
        let result = a.runModal()
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            
            if let firstIndex = self.leftViewController.selectedSessionIndex.first {
                
                let fileManager = FileManager.default
                let session = self.motusLabFile.sessions[firstIndex]
                
                //Delete audio file
                var url = self.fileUrl.appendingPathComponent(FilePath.audio).appendingPathComponent(session.id).appendingPathExtension(session.audioFormat)
                do {
                    try fileManager.removeItem(at: url)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteCurrentSession() Error deleting file in url \(url), context: " + error.localizedDescription)
                }
                
                //delete video files
                url = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.A).appendingPathExtension(FileExtension.mp4)
                do {
                    try fileManager.removeItem(at: url)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteCurrentSession() Error deleting file in url \(url), context: " + error.localizedDescription)
                }
                
                url = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.B).appendingPathExtension(FileExtension.mp4)
                do {
                    try fileManager.removeItem(at: url)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteCurrentSession() Error deleting file in url \(url), context: " + error.localizedDescription)
                }
                
                url = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.C).appendingPathExtension(FileExtension.mp4)
                do {
                    try fileManager.removeItem(at: url)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteCurrentSession() Error deleting file in url \(url), context: " + error.localizedDescription)
                }
                
                url = self.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(session.id + FilePath.D).appendingPathExtension(FileExtension.mp4)
                do {
                    try fileManager.removeItem(at: url)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteCurrentSession() Error deleting file in url \(url), context: " + error.localizedDescription)
                }
                
                //Delete event file
                url = self.fileUrl.appendingPathComponent(FilePath.midi).appendingPathComponent(session.id).appendingPathExtension(FileExtension.event)
                do {
                    try fileManager.removeItem(at: url)
                } catch let error as NSError {
                    Swift.print("WindowController: deleteCurrentSession() Error deleting file in url \(url), context: " + error.localizedDescription)
                }
                
                //Remove item in motusLab file
                var sessions = self.motusLabFile.sessions
                sessions?.remove(at: firstIndex)
                self.motusLabFile.setValue(sessions, forKey: MotusLabFile.PropertyKey.sessionsKey)
                
                //Unload session in playback
                self.leftViewController.setValue(IndexSet(integer: 0), forKey: "selectedSessionIndex")
                self.leftViewController.currentSession = nil
                
                //Update interface
                self.enableModeSegmentedControl()
                
            }
        }
    }
    
    /// Send action to leftViewController (MIDI send)
    @IBAction func changeMidiPlayMenu(_ sender: NSMenuItem) {
        self.leftViewController.changeMidiPlayMenu(sender)
    }
    
    /// Send action to leftViewController (MIDI send)
    @IBAction func changeMidiPlayGroupMenu(_ sender: NSMenuItem) {
        self.leftViewController.changeMidiPlayGroupMenu(sender)
    }
    
}
