//
//  LeftViewController.swift
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
import AVFoundation

class LeftViewController: NSViewController {
    
    @objc dynamic weak var windowController: WindowController!
    weak var acousmoniumViewController: AcousmoniumViewController!
    let preferences = UserDefaults.standard
    @objc dynamic weak var currentSession: Session!
    var timer: Timer!
    var audioMeterTimer: Timer!
    
    @objc dynamic var selectedSessionIndex = IndexSet(integer: 0)
    
    //AUDIO
    var audioRecorder: AudioRecorder!
    var audioCaptureMeter: AudioCaptureMeter!
    var audioPlayer: AudioPlayer!
    var usePlaylist: Bool = false
    var recordAudioPlayer: AudioPlayer!
    /// Save waveforms of each launched section here to avoid reload when launch them again
    /// Key: session id, value(Array): left and right channels
    var sessionWaveform = [String: [[Float]]]()
    
    //Cameras
    var videoRecorder: VideoRecorder!
    var recordCameraViewControllers: [RecordCameraViewController]!
    var playCameraAVPlayers: [AVPlayer]!
    var playCameraViews: [PlayCameraView]!
    
    //MIDI
    var consoleBActivated: Bool = false
    var consoleAMidiRecorder: MIDIRecorder!
    var consoleBMidiRecorder: MIDIRecorder!
    @objc dynamic var consoleAInputDevice: Int = 0 {
        didSet {
            self.consoleAMidiRecorder.initializeSourceConnection(index: self.consoleAInputDevice)
        }
    }
    @objc dynamic var consoleBInputDevice: Int = 0 {
        didSet {
            self.consoleBMidiRecorder.initializeSourceConnection(index: self.consoleBInputDevice)
        }
    }
    var midiPlayer: MIDIPlayer!
    @objc dynamic var consoleAOutputDevice: Int = 0
    @objc dynamic var consoleBOutputDevice: Int = 0
    @objc dynamic var consoleALastMidiMessage: ConsoleLastMidiMessage!
    @objc dynamic var consoleBLastMidiMessage: ConsoleLastMidiMessage!
    var controllersList = [ControllerItem]()
    
    var displayedViewObservation: NSKeyValueObservation?
    var bigCounterObservation: NSKeyValueObservation?
    
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var recordWaveformView: RecordWaveformView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Swift.print("LeftViewController > viewDidLoad")
    }
    
    @IBOutlet weak var playFadersView: PlayFadersView!
    
    func initialization() {
        Swift.print("LeftViewController > initialization()")
        
        if let window = self.view.window, let windowController = window.windowController {
            self.windowController = windowController as? WindowController
            
            //Initialize Audio
            self.initializeAudioMeterLevel()
            
            //Initialize video
            self.videoRecorder = VideoRecorder(leftViewController: self)
            self.initializeCameraSplitView()
            
            //Initialize MIDI Recorders
            self.consoleAMidiRecorder = MIDIRecorder(leftViewController: self, consoleParameters: self.windowController.consoleAParameters)
            self.consoleBMidiRecorder = MIDIRecorder(leftViewController: self, consoleParameters: self.windowController.consoleBParameters)
            self.recordMidiControllerView.consoleAParameters = self.windowController.consoleAParameters
            self.recordMidiControllerView.consoleBParameters = self.windowController.consoleBParameters
            
            //Initialize MIDI Faders
            self.playFadersView.addObservers(windowController: self.windowController)
            
            //Initialize waveform record view
            self.recordWaveformView.initialize(self.windowController)
            
            //Observers
            let displayedViewPath = \WindowController.displayedView
            self.displayedViewObservation = self.windowController.observe(displayedViewPath) { [unowned self] object, change in
                let index = self.windowController.displayedView + 1
                self.tabView.selectTabViewItem(at: index)
                if index == 3 {
                    self.loadSession()
                }
            }
            
            let bigCounterPath = \WindowController.showBigCounter
            self.bigCounterObservation = self.windowController.observe(bigCounterPath) { [unowned self] object, change in
                self.recordWaveformView.loadPlaylistFile()
            }
            
            //Add observer to detect preferences properties
            NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
            self.consoleBActivated = UserDefaults.standard.bool(forKey: PreferenceKey.consoleBActivate)
            
        }
    }
    
    @objc func userDefaultsDidChange(_ notification: Notification) {
        self.consoleBActivated = UserDefaults.standard.bool(forKey: PreferenceKey.consoleBActivate)
        if UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist) {
            if self.audioMeterTimer != nil {
                self.audioMeterTimer.invalidate()
                self.audioMeterTimer = nil
            }
        } else {
            self.initializeAudioMeterLevel()
        }
        self.usePlaylist = UserDefaults.standard.bool(forKey: PreferenceKey.usePlaylist)
        if self.usePlaylist {
            self.recordVuMeter.levels = [0,0]
            self.playVuMeter.levels = [0,0]
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let addMarkerPopoverViewController = segue.destinationController as? AddMarkerPopoverViewController {
            addMarkerPopoverViewController.createMarker(self.windowController.motusLabFile, timePosition: self.windowController.timePosition)
        }
    }
    
    //MARK: - Recording > MIDI controllers
    
    @IBOutlet weak var recordMidiControllerView: MIDIControllersView!
    func updateControllerView() {
        if self.windowController.currentMode == Mode.none || self.windowController.currentMode == Mode.recording {
            self.recordMidiControllerView.setNeedsDisplay(self.recordMidiControllerView.bounds)
        }
    }

    //MARK: - Recording > Cameras
    
    @IBOutlet weak var recordCameraSplitView: NSSplitView!
    
    func addCamera() {
        let cameraCount = self.recordCameraViewControllers.count
        if cameraCount < 4 {
            let height = self.recordCameraSplitView.frame.height
            let width = self.recordCameraSplitView.frame.width / CGFloat(cameraCount + 1)
            let x = width * CGFloat(cameraCount)
            let newView = NSView(frame: CGRect(x: x, y: 0, width: width, height: height))
            self.recordCameraSplitView.addSubview(newView)
            self.recordCameraSplitView.adjustSubviews()
            self.addRecordCamera(in: newView, index: cameraCount)
        }
    }
    
    func initializeCameraSplitView() {
        self.recordCameraSplitView.arrangesAllSubviews = true
        self.recordCameraViewControllers = []
        self.addRecordCamera(in: self.recordCameraSplitView.subviews.first!, index: 0)
    }
    
    func addRecordCamera(in view: NSView, index: Int) {
        var cameraName = "A"
        switch index {
        case 1:
            cameraName = "B"
        case 2:
            cameraName = "C"
        case 3:
            cameraName = "D"
        default:
            break
        }
        let newRecordCameraViewController = RecordCameraViewController(nibName: "RecordCamera", bundle: nil, leftViewController: self, name: cameraName)
        self.recordCameraViewControllers.append(newRecordCameraViewController)
        view.addSubview(newRecordCameraViewController.view)
        newRecordCameraViewController.view.addInViewConstraints(superView: view)
    }
    
    func removeCamera(_ name: String) {
        var indexCamera = 0
        for (index, camera) in self.recordCameraViewControllers.enumerated() {
            if camera.name == name {
                indexCamera = index
                break
            }
        }
        self.recordCameraSplitView.subviews[indexCamera].removeFromSuperview()
        self.recordCameraSplitView.adjustSubviews()
        if let device = self.recordCameraViewControllers[indexCamera].cameraDevice {
            self.videoRecorder.removeInputConnection(device)
        }
        self.recordCameraViewControllers.remove(at: indexCamera)
    }
    
    //MARK: - Recording > Audio
    
    @IBOutlet weak var recordVuMeter: VuMeter!
    
    /// Initialize AudioCaptureMeter to render the audio input level
    /// Start the timer which render levels
    func initializeAudioMeterLevel() {
        if self.audioCaptureMeter == nil {
            self.audioCaptureMeter = AudioCaptureMeter()
        } else {
            self.audioCaptureMeter.session.startRunning()
        }
        self.audioMeterTimer = Timer(timeInterval: 0.01, target: self, selector: #selector(self.updateMeter), userInfo: nil, repeats: true)
        RunLoop.current.add(self.audioMeterTimer, forMode: .common)
    }
    
    @objc func updateMeter() {
        guard self.audioCaptureMeter != nil else {
            Swift.print("RecordViewController: updateMeter Error audioCaptureMeter is nil")
            return
        }
        
        if !self.usePlaylist {
            let meterValue = self.audioCaptureMeter.meterLevels //-100 +6
            self.recordVuMeter.levels = [(meterValue.left + 100) / 1.06 , (meterValue.right + 100) / 1.06]
        }
    }
    
    //MARK: - Recording > Commands
    
    func startRecording() {
        
        if let windowController = self.windowController {
            
            guard windowController.fileUrl != nil else {
                Swift.print("LeftViewController: startRecording Error fileURL is nil")
                return
            }
            
            //Create a new session and select it in tableView
            self.currentSession = windowController.motusLabFile.createSession()
            self.currentSession.setValue(true, forKey: Session.PropertyKey.isRecordingKey)
            
            //Initialize MIDI file
            if self.windowController.midiControllerEvents == nil {
                self.windowController.midiControllerEvents = []
            }
            self.windowController.midiControllerEvents.removeAll()
            self.consoleAMidiRecorder.startRecording()
            self.consoleBMidiRecorder.startRecording()
            
            //Save configurations of controllers
            self.currentSession.consoleAControllers = windowController.consoleAParameters.filterControllers
            self.currentSession.consoleBControllers = windowController.consoleBParameters.filterControllers
            
            //use playlist = initialize audio player
            self.usePlaylist = false
            if let playlistSelectedFile = windowController.playlistSelectedFileIndex {
                if self.preferences.bool(forKey: PreferenceKey.usePlaylist) && playlistSelectedFile.count > 0 && self.windowController.playlistFiles.count > 0 {
                    if let first = playlistSelectedFile.first {
                        let playlistFile = windowController.playlistFiles[first]
                        let fileUrl = playlistFile.url!
                        self.recordAudioPlayer = AudioPlayer(self)
                        self.recordAudioPlayer.createAudioPlayer(fileUrl)
                        self.currentSession.duration = playlistFile.duration
                        self.currentSession.audioFile = fileUrl
                        self.usePlaylist = true
                    }
                }
            }
            
            //Don't use playlist = initialize audio recorder
            if !self.usePlaylist {
                let audioURL = windowController.fileUrl.appendingPathComponent(FilePath.audio)
                let audioFormat = AudioFormat.typeFrom(self.preferences.integer(forKey: PreferenceKey.audioFormat))
                self.audioRecorder = AudioRecorder(audioURL, audioFormat: audioFormat, leftViewController: self)
                self.audioRecorder.createAudioRecorder()
            }
            
            
            //Initialize video recorders
            for camera in self.recordCameraViewControllers {
                if camera.cameraDevice != nil {
                    self.videoRecorder.initializeVideoAssetWriter(camera.cameraDevice, session: self.currentSession)
                }
            }
            
            //Switch to recording mode
            windowController.currentMode = Mode.recording
            
            //Start counter timer
            self.timer = Timer(timeInterval: 0.01, target: self, selector: #selector(self.updateCounter), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer, forMode: .common)
            
            //Start audio Recording
            if self.usePlaylist {
                //Use playlist = play file
                self.recordAudioPlayer.startPlaying()
            } else {
                // Don't use playlist = start recording
                self.audioRecorder.startRecord()
            }
            
        }
    }
    
    func stopRecording() {
        
        if let currentSession = self.currentSession {
            currentSession.setValue(false, forKey: Session.PropertyKey.isRecordingKey)
        }
        
        //Stop timer
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
        
        //End of recording mode
        self.windowController.currentMode = Mode.none
        
        //Stop audio playing (playlist) or recording
        if self.usePlaylist {
            self.recordAudioPlayer.stopPlaying()
            let audioExt = self.currentSession.audioFile.pathExtension
            let destinationUrl =  self.windowController.fileUrl.appendingPathComponent(FilePath.audio).appendingPathComponent(self.currentSession.id).appendingPathExtension(audioExt)
            let fileManager = FileManager.default
            do {
                try fileManager.copyItem(at: self.currentSession.audioFile, to: destinationUrl)
                /*if let recordAudioPlayer = self.recordAudioPlayer, let duration = recordAudioPlayer.duration {
                    self.currentSession.duration = Float(duration)
                }*/
            } catch let error as NSError {
                Swift.print("LeftViewController: stopRecording() Error copying url \(String(describing: self.currentSession.audioFile)) to url \(destinationUrl), context: " + error.localizedDescription)
            }
        } else {
            self.audioRecorder.stopRecord()
        }
        
        //Stop video recording
        self.videoRecorder.stopRecording()
        
        //Save MIDI file
        self.windowController.saveMidi()
        
        //Save file
        self.windowController.saveFile()
        
        //Select last session
        let lastIndex = self.windowController.motusLabFile.sessions.count
        self.selectedSessionIndex = IndexSet(integer: lastIndex - 1)
        
    }
    
    @objc func updateCounter() {
        if let windowController = self.windowController {
            if windowController.currentMode == Mode.recording {
                
                if self.usePlaylist {
                    
                    guard self.recordAudioPlayer != nil else {
                        Swift.print("LeftViewController: updateCounter Error recordAudioPlayer is nil")
                        return
                    }
                    let timePosition = Float(self.recordAudioPlayer.timePosition)
                    self.windowController.setValue(timePosition, forKey: "timePosition")
                    
                    let meterValue = self.recordAudioPlayer.meterValue //-160 0
                    self.recordVuMeter.levels = [(meterValue.left + 160) / 1.6 , (meterValue.right + 160) / 1.6]
                    
                } else {
                    
                    guard self.audioRecorder != nil else {
                        Swift.print("LeftViewController: updateCounter Error audioRecorder is nil")
                        return
                    }
                    let timePosition = Float(self.audioRecorder.timePosition)
                    windowController.timePosition = timePosition
                    self.currentSession.setValue(timePosition, forKey: Session.PropertyKey.durationKey)
                    
                }
                
            } else if windowController.currentMode == Mode.playing {
                
                guard self.audioPlayer != nil else {
                    Swift.print("LeftViewController: updateCounter Error audioPlayer is nil")
                    return
                }
                
                let timePosition = Float(self.audioPlayer.timePosition)
                self.windowController.setValue(timePosition, forKey: "timePosition")
                
                let meterValue = self.audioPlayer.meterValue //-160 0
                self.playVuMeter.levels = [(meterValue.left + 160) / 1.6 , (meterValue.right + 160) / 1.6]
                
            }
        }
        
    }
    
    //MARK: - Playing > Audio
    
    @IBOutlet weak var playTimelineView: PlayTimelineView!
    @IBOutlet weak var playVuMeter: VuMeter!
    
    /// Load session
    /// This function initialize all elements to play a session
    func loadSession() {
        
        Swift.print("LeftViewController > loadSession")
    
        guard self.playTimelineView != nil && self.windowController.motusLabFile.sessions.count > 0 else {
            return
        }
        if let firstIndex = self.selectedSessionIndex.first {
            
            guard !self.windowController.motusLabFile.sessions[firstIndex].isRecording else {
                return
            }
            
            if self.windowController.currentMode == Mode.playing {
                self.stopPlaying()
            }
            
            self.currentSession = self.windowController.motusLabFile.sessions[firstIndex]
            
            self.playTimelineView.leftViewController = self
            
            if case 0..<self.windowController.motusLabFile.sessions.count = firstIndex {
                
                //Initialize players
                if self.midiPlayer  == nil {
                    self.midiPlayer = MIDIPlayer(self)
                }
                if self.audioPlayer == nil {
                    self.audioPlayer = AudioPlayer(self)
                }
                
                //Select session
                self.setValue(self.windowController.motusLabFile.sessions[firstIndex], forKey: "currentSession")
                
                //Load audio waveform if needed
                //Waveform data is saved in viewController to avoid loading several times the same waveform
                let sessionId = self.currentSession.id!
                if self.sessionWaveform[sessionId] == nil {
                    var audioExt = self.currentSession.audioFormat
                    if self.currentSession.audioFile != nil {
                        audioExt = self.currentSession.audioFile.pathExtension
                    }
                    let audioFileUrl = self.windowController.fileUrl.appendingPathComponent(FilePath.audio).appendingPathComponent(sessionId).appendingPathExtension(audioExt)
                    let audioAnalyzer = AudioAnalyzer(audioFileUrl)
                    if let waveform = audioAnalyzer.computeChannelsData() {
                        self.sessionWaveform[sessionId] = waveform
                    } else {
                        Swift.print("PlayViewController: loadSession Cannot compute waveform!")
                    }
                    
                }
                
                self.playTimelineView.playWaveformView.waveform = self.sessionWaveform[sessionId]
                self.loadMidiControllers()
                self.loadAudioFile()
                self.loadCameras()
                self.updateLevelsWithoutPlaying()
                self.windowController.setValue(0, forKey: "timePosition")
            }
        }
    }
    
    /// Initialize the audio file in audio player
    func loadAudioFile() {
        let audioFileURL = self.windowController.fileUrl.appendingPathComponent(FilePath.audio).appendingPathComponent(self.currentSession.id!).appendingPathExtension(self.currentSession.audioFormat)
        self.audioPlayer.createAudioPlayer(audioFileURL)
    }
    
    /// Open midi controller events file and load them
    func loadMidiControllers() {
        let sessionId = self.currentSession.id!
        let url = self.windowController.fileUrl.appendingPathComponent(FilePath.midi).appendingPathComponent(sessionId).appendingPathExtension(FileExtension.event)
        do {
            let data = try Data(contentsOf: url)
            self.windowController.midiControllerEvents = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MIDIControllerEvent]
            if self.windowController.midiControllerEvents.count > 0 {
                self.playTimelineView.playControllersView.convertEvents()
                self.midiPlayer.loadSession()
                self.loadMidiPlayMenu()
            }
        } catch let error as NSError {
            Swift.print("LeftViewController: loadMidiControllers() Error openning url \(url), context: " + error.localizedDescription)
        }
    }
    
    func updateLevelsWithoutPlaying() {
        if self.windowController.currentMode != Mode.playing {
            let waveformValues = self.playTimelineView.playWaveformView.waveform!
            let timePosition = Float(self.audioPlayer.timePosition)
            let indexWaveform = Int((timePosition * Float(waveformValues[0].count)) / self.currentSession.duration)
            let leftValue = waveformValues[0][indexWaveform].decibel
            let rightValue = waveformValues[1][indexWaveform].decibel
            self.playVuMeter.levels = [(leftValue + 160) / 1.6, (rightValue + 160) / 1.6]
        }
    }
    
    func endOfPlayback() {
        //If using playlist during recording
        if self.windowController.currentMode == Mode.recording {
            self.stopRecording()
            self.windowController.setValue(NSButton.StateValue.off, forKey: "toolbarRecord")
        }
        
        self.windowController.currentMode = Mode.none
    }
    
    //MARK: - Playing > Video cameras
    
    @IBOutlet weak var playCameraSplitView: NSSplitView!
    
    /// Open video files and load them in AVPlayers
    func loadCameras() {
        
        let sessionId = self.currentSession.id!
        let urlVideoA = self.windowController.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(sessionId + "-A").appendingPathExtension("mp4")
        let urlVideoB = self.windowController.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(sessionId + "-B").appendingPathExtension("mp4")
        let urlVideoC = self.windowController.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(sessionId + "-C").appendingPathExtension("mp4")
        let urlVideoD = self.windowController.fileUrl.appendingPathComponent(FilePath.movie).appendingPathComponent(sessionId + "-D").appendingPathExtension("mp4")
        
        self.playCameraSplitView.subviews.removeAll()
        self.playCameraSplitView.arrangesAllSubviews = true
        
        if self.playCameraViews == nil {
            self.playCameraViews = []
            self.playCameraAVPlayers = []
        }
        self.playCameraViews.removeAll()
        self.playCameraAVPlayers.removeAll()
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: urlVideoA.path) {
            let cameraAVPlayer = AVPlayer(url: urlVideoA)
            self.playCameraAVPlayers.append(cameraAVPlayer)
        }
        if fileManager.fileExists(atPath: urlVideoB.path) {
            let cameraAVPlayer = AVPlayer(url: urlVideoB)
            self.playCameraAVPlayers.append(cameraAVPlayer)
        }
        if fileManager.fileExists(atPath: urlVideoC.path) {
            let cameraAVPlayer = AVPlayer(url: urlVideoC)
            self.playCameraAVPlayers.append(cameraAVPlayer)
        }
        if fileManager.fileExists(atPath: urlVideoD.path) {
            let cameraAVPlayer = AVPlayer(url: urlVideoD)
            self.playCameraAVPlayers.append(cameraAVPlayer)
        }
        
        if self.playCameraAVPlayers.count > 0 {
            let width = self.playCameraSplitView.frame.size.width / CGFloat(self.playCameraAVPlayers.count)
            var cameraRect = CGRect(x: 0, y: 0, width: width, height: self.playCameraSplitView.frame.size.height)
            for (index,camera) in self.playCameraAVPlayers.enumerated() {
                cameraRect.origin.x = width * CGFloat(index)
                let cameraView = PlayCameraView(frame: cameraRect)
                cameraView.loadAVPlayer(camera)
                self.playCameraSplitView.addSubview(cameraView)
            }
        }
        
        self.playCameraSplitView.adjustSubviews()

    }
    
    //MARK: - Playing > Menu controllers
    
    @IBOutlet var controllersMenu: NSMenu!
    @IBAction func showControllersMenu(_ sender: Any) {
        let event = NSApp.currentEvent!
        NSMenu.popUpContextMenu(self.controllersMenu, with: event, for: sender as! NSButton)
    }
    
    @IBAction func changeControllersMenu(_ sender: Any) {
        let tag = (sender as! NSMenuItem).tag
        let controllerCount = self.controllersList.count
        let controllerConsoleBIndex = self.controllersList.filter( { $0.console == 0 } ).count - 1
            switch tag {
            case -1:
                for n in 0..<controllerCount {
                    self.controllersList[n].show = true
                }
            case 0:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 0 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 1:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 1 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 2:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 0 && n < 8 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 3:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 0 && n > 7 && n < 16 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 4:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 0 && n > 15 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 5:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 1 && n - controllerConsoleBIndex < 8 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 6:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 1 && n - controllerConsoleBIndex > 7 && n - controllerConsoleBIndex < 16 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            case 7:
                for n in 0..<controllerCount {
                    if self.controllersList[n].console == 1 && n - controllerConsoleBIndex > 15 {
                        self.controllersList[n].show = true
                    } else {
                        self.controllersList[n].show = false
                    }
                }
            default:
                break
            }
            self.playTimelineView.playControllersView.setNeedsDisplay(self.playTimelineView.playControllersView.bounds)
    }
    
    //MARK: - Playing > Menu midiPlay
    
    @IBOutlet var midiPlayMenu: NSMenu!
    @IBAction func showMidiPlayMenu(_ sender: Any) {
        let event = NSApp.currentEvent!
        NSMenu.popUpContextMenu(self.midiPlayMenu, with: event, for: sender as! NSButton)
    }
    
    @IBOutlet weak var midiPlaySubMenu: NSMenuItem!
    @IBOutlet weak var midiPlayGroupSubMenu: NSMenuItem!
    
    /// Create the menu with lists of controllers, group of 8 controllers and  consoles
    func loadMidiPlayMenu() {
        self.midiPlaySubMenu.submenu?.removeAllItems()
        self.midiPlayGroupSubMenu.submenu?.removeAllItems()
        var group: Int = 1
        var firstGroupItem: Int = 1
        for controller in self.controllersList {
            if controller.id == self.playTimelineView.playControllersView.consoleBStartId {
                self.midiPlaySubMenu.submenu?.addItem(NSMenuItem.separator())
                self.midiPlayGroupSubMenu.submenu?.addItem(NSMenuItem.separator())
                group = 1
            }
            var controllerNumber = controller.id + 1
            if controller.console == 1 {
                controllerNumber -= self.playTimelineView.playControllersView.consoleBStartId
            }
            self.midiPlaySubMenu.submenu?.addItem(withTitle: String(controllerNumber), action: #selector(changeMidiPlayMenu), keyEquivalent: "")
            self.midiPlaySubMenu.submenu?.items.last!.tag = controller.id
            
            if group == 1 {
                self.midiPlayGroupSubMenu.submenu?.addItem(withTitle: String(controllerNumber), action: #selector(changeMidiPlayGroupMenu), keyEquivalent: "")
                self.midiPlayGroupSubMenu.submenu?.items.last!.tag = controller.id
                firstGroupItem = controllerNumber
            } else {
                self.midiPlayGroupSubMenu.submenu?.items.last!.title = String(firstGroupItem) + "-" + String(controllerNumber)
            }
            
            if group < 8 {
                group += 1
            } else {
                group = 1
            }
        }
    }
    
    /// User select a controller
    @IBAction func changeMidiPlayMenu(_ sender: NSMenuItem) {
        let tag = sender.tag
        let enable = self.controllersList[tag].enable
        self.controllersList[tag].enable = !enable
        self.playTimelineView.playControllersView.setNeedsDisplay(self.playTimelineView.playControllersView.bounds)
        self.playFadersView.setNeedsDisplay(self.playFadersView.bounds)
        if let acousmoContainer = acousmoniumViewController.acousmoniumView.subviews.first {
            for subview in acousmoContainer.subviews {
                subview.setNeedsDisplay(subview.bounds)
            }
        }
    }
    
    /// User select a group of controllers
    @IBAction func changeMidiPlayGroupMenu(_ sender: NSMenuItem) {
        let tag = sender.tag
        let console = self.controllersList[tag].console
        let enable = self.controllersList[tag].enable
        for n in tag..<(tag + 8) {
            if n > self.controllersList.count - 1 {
                break
            }
            if self.controllersList[n].console == console {
                self.controllersList[n].enable = !enable
            } else {
                break
            }
        }
        self.playTimelineView.playControllersView.setNeedsDisplay(self.playTimelineView.playControllersView.bounds)
        self.playFadersView.setNeedsDisplay(self.playFadersView.bounds)
        if let acousmoContainer = acousmoniumViewController.acousmoniumView.subviews.first {
            for subview in acousmoContainer.subviews {
                subview.setNeedsDisplay(subview.bounds)
            }
        }
    }
    
    // User select a console
    @IBAction func changeMidiPlayConsoleMenu(_ sender: NSMenuItem) {
        let tag = sender.tag
        var enable = true
        var first = true
        for n in 0..<self.controllersList.count {
            if self.controllersList[n].console == tag {
                if first {
                    first = false
                    enable = self.controllersList[n].enable
                }
                self.controllersList[n].enable = !enable
            }
        }
        self.playTimelineView.playControllersView.setNeedsDisplay(self.playTimelineView.playControllersView.bounds)
        self.playFadersView.setNeedsDisplay(self.playFadersView.bounds)
        if let acousmoContainer = acousmoniumViewController.acousmoniumView.subviews.first {
            for subview in acousmoContainer.subviews {
                subview.setNeedsDisplay(subview.bounds)
            }
        }
    }
    
    func controllerColor(from number: Int, console: Int) -> NSColor {
        
        if let windowController = self.windowController {
            
            if windowController.displayedView == 1 {
                
                if console == 0 && windowController.consoleAControllerColors.count > number {
                    return windowController.consoleAControllerColors[number] ?? NSColor.black
                } else if self.consoleBActivated && console == 1 && windowController.consoleBControllerColors.count > number {
                    return windowController.consoleBControllerColors[number] ?? NSColor.black
                }
                
            } else if windowController.displayedView == 2 {
                
                for controllerItem in self.controllersList {
                    if controllerItem.ctl == number && controllerItem.console == console {
                        if controllerItem.enable {
                            if console == 0 && windowController.consoleAControllerColors.count > number {
                                return windowController.consoleAControllerColors[number] ?? NSColor.black
                            } else if self.consoleBActivated && console == 1 && windowController.consoleBControllerColors.count > number {
                                return windowController.consoleBControllerColors[number] ?? NSColor.black
                            }
                        }
                        break
                    }
                }
                
            }
        }
        
        return NSColor.lightGray
        
    }
    
    //MARK: - Playing > Commands
    
    func startPlaying() {
        
        self.midiPlayer.startPlaying()
        self.audioPlayer.startPlaying()
        
        for camera in self.playCameraAVPlayers {
            camera.play()
        }
        
        //Start timer
        self.timer = Timer(timeInterval: 0.001, target: self, selector: #selector(self.updateCounter), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer, forMode: .common)
        
        self.windowController.currentMode = Mode.playing
    }
    
    func pausePlaying() {
        
        self.midiPlayer.stopPlaying()
        self.audioPlayer.pausePlaying()
        
        for camera in self.playCameraAVPlayers {
            camera.pause()
        }
        
        //Stop timer
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
        
        self.windowController.currentMode = Mode.none
    }
    
    func stopPlaying() {
        
        self.goToTime(0)
        
        self.midiPlayer.stopPlaying()
        self.audioPlayer.stopPlaying()
        
        for camera in self.playCameraAVPlayers {
            camera.pause()
        }
        
        //Stop timer
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
        
        self.windowController.currentMode = Mode.none
        
        if self.windowController.toolbarPlay == .on {
            self.windowController.setValue(NSButton.StateValue.off, forKey: "toolbarPlay")
        }
    }
    
    func next() {
        let timePosition = Float(self.windowController.timePosition)
        if timePosition + 5 < self.currentSession.duration {
            self.goToTime(timePosition + 5)
        }
    }
    
    func prev() {
        let timePosition = Float(self.windowController.timePosition)
        if timePosition - 5 >= 0 {
            self.goToTime(timePosition - 5)
        } else {
            self.goToTime(0)
        }
    }
    
    func goToTime(_ position: Float) {
        guard self.audioPlayer != nil else {
            Swift.print("LeftViwController: updateCounter Error audioPlayer is nil")
            return
        }
        self.audioPlayer.audioPlayer.currentTime = Double(position)
        self.windowController.setValue(position, forKey: "timePosition")
        
        for camera in self.playCameraAVPlayers {
            let timeScale = camera.currentTime().timescale
            let timePosition = CMTime(seconds: Double(position), preferredTimescale: timeScale)
            camera.seek(to: timePosition, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        self.updateLevelsWithoutPlaying()
        
    }
    
}
