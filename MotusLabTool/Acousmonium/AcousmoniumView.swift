//
//  AcousmoniumView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class AcousmoniumView: NSView {
    
     weak var windowController: WindowController! {
            didSet {
                if self.windowController != nil {
                    self.initializeObserver()
                }
            }
        }
        
        @objc dynamic weak var acousmoniumFile: AcousmoniumFile!
        
        var acousmoContainer: AcousmoContainer!
        
        var acousmoniumFileObservation: NSKeyValueObservation?
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
        }
        
        required init?(coder decoder: NSCoder) {
            super.init(coder: decoder)
        }
        
        func initializeObserver() {
            let acousmoniumFilePath = \WindowController.selectedAcousmoniumFile
            self.acousmoniumFileObservation = self.windowController.observe(acousmoniumFilePath) { [unowned self] object, change in
                if let acousmoniumFile = self.windowController.selectedAcousmoniumFile {
                    self.acousmoniumFile = acousmoniumFile
                    self.acousmoContainer = AcousmoContainer(frame: NSZeroRect, acousmoniumFile: self.acousmoniumFile, windowController: self.windowController)
                    self.addSubview(self.acousmoContainer)
                    self.acousmoContainer.updateSize()
                    self.acousmoContainer.loadLoudspeakers()
                } else {
                    self.acousmoniumFile = nil
                    if self.acousmoContainer != nil {
                        self.acousmoContainer.removeFromSuperview()
                        self.acousmoContainer = nil
                    }
                }
            }
        }
        
    }

    class AcousmoContainer: NSView {
        
        weak var windowController: WindowController!
        @objc dynamic weak var acousmoniumFile: AcousmoniumFile!
        
        var ratioSize = CGSize(width: 300, height: 400)
        
        var acousmoOpacity: Float = 0.8 {
            didSet {
                self.updateLoudspeakerOpacity()
            }
        }
        var acousmoSize: Float = 0.25 {
            didSet {
                self.updateLoudspeakerSize()
            }
        }
        var imageObservation: NSKeyValueObservation?
        var hpObservation: NSKeyValueObservation?
        
        var selectedLoudspeaker: (loudspeaker: AcousmoLoudspeakerView?, position: CGPoint) = (nil,NSZeroPoint)
        
        init(frame frameRect: NSRect, acousmoniumFile: AcousmoniumFile, windowController: WindowController) {
            super.init(frame: frameRect)
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.white.cgColor
            
            self.acousmoniumFile = acousmoniumFile
            self.windowController = windowController
            
            //Observers
            let imagePath = \AcousmoniumFile.image
            self.imageObservation = self.acousmoniumFile.observe(imagePath) { [unowned self] object, change in
                if let image = NSImage(data: self.acousmoniumFile.image) {
                    self.ratioSize = image.size
                    self.layer?.contents = image
                    self.updateSize()
                } else {
                    self.layer?.contents = nil
                }
            }
            let loudspeakersPath = \AcousmoniumFile.acousmoLoudspeakers
            self.hpObservation = self.acousmoniumFile.observe(loudspeakersPath) { [unowned self] object, change in
                self.loadLoudspeakers()
            }
            
            //Add observer to detect preferences properties
            NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
            self.acousmoOpacity = UserDefaults.standard.float(forKey: PreferenceKey.acousmoOpacity)
            self.acousmoSize = UserDefaults.standard.float(forKey: PreferenceKey.acousmoSize)
            
            self.updateSize()
        }
        
        required init?(coder decoder: NSCoder) {
            super.init(coder: decoder)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func userDefaultsDidChange(_ notification: Notification) {
            let opacity = UserDefaults.standard.float(forKey: PreferenceKey.acousmoOpacity)
            if self.acousmoOpacity != opacity {
                self.acousmoOpacity = opacity
            }
            let size = UserDefaults.standard.float(forKey: PreferenceKey.acousmoSize)
            if self.acousmoSize != size {
                self.acousmoSize = size
            }
        }
        
        override func resize(withOldSuperviewSize oldSize: NSSize) {
            self.updateSize()
        }
        
        func updateSize() {
            if let superview = self.superview {
                let superviewBounds = superview.bounds
                let factor = min(superviewBounds.size.width / self.ratioSize.width, superviewBounds.size.height / self.ratioSize.height)
                let width = self.ratioSize.width * factor
                let height = self.ratioSize.height * factor
                let x = (superviewBounds.size.width - width) / 2
                let y = (superviewBounds.size.height - height) / 2
                let frame = CGRect(x: x, y: y, width: width, height: height)
                self.frame = frame
            }
        }
        
        func loadLoudspeakers() {
            
            //Add missing loudspeakers
            for loudspeaker in self.acousmoniumFile.acousmoLoudspeakers {
                if self.subviews.filter( { ($0 as! AcousmoLoudspeakerView).acousmoLoudspeaker == loudspeaker } ).count == 0 {
                    self.createLoudspeaker(loudspeaker)
                }
            }
            
            //Delete removed loudspeaker
            for subview in self.subviews {
                if let acousmoLoudspeaker = (subview as! AcousmoLoudspeakerView).acousmoLoudspeaker {
                    if !self.acousmoniumFile.acousmoLoudspeakers.contains(acousmoLoudspeaker) {
                        subview.removeFromSuperview()
                        break
                    }
                }
            }
        }
        
        func createLoudspeaker(_ acousmoLoudspeaker: AcousmoLoudspeaker) {
            let defaultFrame = CGRect(x: self.bounds.midX, y: self.bounds.midY, width: self.bounds.size.width * CGFloat(self.acousmoSize), height: self.bounds.size.height * CGFloat(self.acousmoSize))
            let acousmoLoudspeakerView = AcousmoLoudspeakerView(frame: defaultFrame, acousmoLoudspeaker: acousmoLoudspeaker, windowController: self.windowController)
            self.addSubview(acousmoLoudspeakerView)
            acousmoLoudspeakerView.updateFrame()
            acousmoLoudspeakerView.updateObserver()
        }
        
        func updateLoudspeakerOpacity() {
            for subview in self.subviews {
                (subview as! AcousmoLoudspeakerView).updateAlpha()
            }
        }
        
        func updateLoudspeakerSize() {
            for subview in self.subviews {
                (subview as! AcousmoLoudspeakerView).updateFrame()
            }
        }
        
        override func mouseDown(with event: NSEvent) {
            let mouse = self.convert(event.locationInWindow, from: nil)
            self.selectedLoudspeaker.loudspeaker = nil
            for subview in self.subviews {
                if NSPointInRect(mouse, subview.frame) {
                    let position = CGPoint(x: mouse.x - subview.frame.origin.x, y: mouse.y - subview.frame.origin.y)
                    self.selectedLoudspeaker = (subview as? AcousmoLoudspeakerView, position)
                }
            }
        }
        
        override func mouseDragged(with event: NSEvent) {
            if let loudspeaker = self.selectedLoudspeaker.loudspeaker {
                let mouse = self.convert(event.locationInWindow, from: nil)
                let refSize = self.frame.size.width * CGFloat(self.acousmoSize)
                let x = (mouse.x - self.selectedLoudspeaker.position.x  + (refSize / 2)) / self.frame.size.width
                let y = (mouse.y - self.selectedLoudspeaker.position.y + (refSize / 2)) / self.frame.size.height
                loudspeaker.acousmoLoudspeaker.position = CGPoint(x: x, y: y)
                loudspeaker.updateFrame()
            }
        }
        
        override func mouseUp(with event: NSEvent) {
            self.selectedLoudspeaker.loudspeaker = nil
            self.windowController.saveAcousmoniumFile(self.windowController.selectedAcousmoniumFile)
        }
        
    }

    class AcousmoLoudspeakerView: NSView {
        
        weak var windowController: WindowController!
        weak var acousmoLoudspeaker: AcousmoLoudspeaker!
        var value: Int = 0 {
            didSet {
                //self.updateAlpha()
                self.updateFrame()
            }
        }
        
        var mouseClic = CGPoint(x: -1, y: -1)
        
        var consoleObservation: NSKeyValueObservation?
        var inputObservation: NSKeyValueObservation?
        var valueObservation: NSKeyValueObservation?
        var editObservation: NSKeyValueObservation?
       
        init(frame frameRect: NSRect, acousmoLoudspeaker: AcousmoLoudspeaker, windowController: WindowController) {
            super.init(frame: frameRect)
            self.acousmoLoudspeaker = acousmoLoudspeaker
            self.windowController = windowController
            self.wantsLayer = true
            self.alphaValue = 0.7
            
            //Observers
            let consolePath = \AcousmoLoudspeaker.console
            self.consoleObservation = self.acousmoLoudspeaker.observe(consolePath) { [unowned self] object, change in
                self.updateObserver()
            }
            
            let inputPath = \AcousmoLoudspeaker.input
            self.inputObservation = self.acousmoLoudspeaker.observe(inputPath) { [unowned self] object, change in
                self.updateObserver()
            }
            
            let editPath = \WindowController.editAcousmonium
            self.editObservation = self.windowController.observe(editPath) { [unowned self] object, change in
                self.updateFrame()
            }
        }
        
        required init?(coder decoder: NSCoder) {
            super.init(coder: decoder)
        }
        
        func updateObserver() {
            if self.acousmoLoudspeaker.console == 0 {
                let consoleALastMidiMessagePath = \LeftViewController.consoleALastMidiMessage
                self.valueObservation = self.windowController.leftViewController.observe(consoleALastMidiMessagePath) { [unowned self] object, change in
                    if self.windowController.leftViewController.consoleALastMidiMessage.number == self.acousmoLoudspeaker.input {
                        self.value = self.windowController.leftViewController.consoleALastMidiMessage.value
                    }
                }
            } else if self.acousmoLoudspeaker.console == 1 {
                let consoleBLastMidiMessagePath = \LeftViewController.consoleBLastMidiMessage
                self.valueObservation = self.windowController.leftViewController.observe(consoleBLastMidiMessagePath) { [unowned self] object, change in
                    if self.windowController.leftViewController.consoleBLastMidiMessage.number == self.acousmoLoudspeaker.input {
                        self.value = self.windowController.leftViewController.consoleBLastMidiMessage.value
                    }
                }
            }
        }
        
        override func resize(withOldSuperviewSize oldSize: NSSize) {
            self.updateFrame()
        }
        
        func updateAlpha() {
            if let superview = self.superview, let acousmoContainer = superview as? AcousmoContainer {
                if self.windowController.editAcousmonium {
                    self.alphaValue = CGFloat(acousmoContainer.acousmoOpacity)
                } else {
                    if self.value == 0 {
                        self.alphaValue = 0
                    } else {
                        if self.alphaValue != CGFloat(acousmoContainer.acousmoOpacity) {
                            self.alphaValue = CGFloat(acousmoContainer.acousmoOpacity)
                        }
                    }
                }
            }
        }
        
        func updateFrame() {
            if let superview = self.superview, let acousmoContainer = superview as? AcousmoContainer {
                var refSize = superview.frame.size.width * CGFloat(acousmoContainer.acousmoSize)
                if !self.windowController.editAcousmonium {
                    refSize = superview.frame.size.width * CGFloat(acousmoContainer.acousmoSize * (Float(value) / 128))
                }
                var x = superview.frame.size.width * self.acousmoLoudspeaker.position.x
                var y = superview.frame.size.height * self.acousmoLoudspeaker.position.y
                x -= (refSize / 2)
                y -= (refSize / 2)
                let frame = CGRect(x: x, y: y, width: refSize, height: refSize)
                self.frame = frame
            }
            self.updateAlpha()
        }
        
        override func draw(_ dirtyRect: NSRect) {
            if let context = NSGraphicsContext.current?.cgContext {
                context.saveGState()
                if let color = self.windowController.consoleAControllerColors[self.acousmoLoudspeaker.input] {
                    context.setFillColor(color.cgColor)
                } else {
                    context.setFillColor(NSColor.black.cgColor)
                }
                context.addEllipse(in: self.bounds)
                context.drawPath(using: .fill)
                context.restoreGState()
            }
        }
        
    }
