//
//  AcousmoniumView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 02/09/2019.
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
            
            //Delete previous acousmonium
            if self.acousmoContainer != nil {
                self.acousmoContainer.removeFromSuperview()
            }
            
            //Add new acousmonium
            if let acousmoniumFile = self.windowController.selectedAcousmoniumFile {
                self.acousmoniumFile = acousmoniumFile
                self.acousmoContainer = AcousmoContainer(frame: NSZeroRect, acousmoniumFile: self.acousmoniumFile, windowController: self.windowController)
                self.addSubview(self.acousmoContainer)
                self.acousmoContainer.updateSize()
                self.acousmoContainer.loadImage()
                self.acousmoContainer.loadLoudspeakers()
            } else {
                self.acousmoContainer = nil
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
    var showImageObservation: NSKeyValueObservation?
    var hpObservation: NSKeyValueObservation?
    var selectedLoudspeakerIndexObservation: NSKeyValueObservation?
    
    var selectedLoudspeaker: (loudspeaker: AcousmoLoudspeakerView?, position: CGPoint) = (nil,NSZeroPoint)
    
    init(frame frameRect: NSRect, acousmoniumFile: AcousmoniumFile, windowController: WindowController) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        self.acousmoniumFile = acousmoniumFile
        self.windowController = windowController
        
        //Observers
        let showImagePath = \AcousmoniumFile.showImage
        self.showImageObservation = self.acousmoniumFile.observe(showImagePath) { [unowned self] object, change in
            self.loadImage()
        }
        let imagePath = \AcousmoniumFile.image
        self.imageObservation = self.acousmoniumFile.observe(imagePath) { [unowned self] object, change in
            self.loadImage()
        }
        let loudspeakersPath = \AcousmoniumFile.acousmoLoudspeakers
        self.hpObservation = self.acousmoniumFile.observe(loudspeakersPath) { [unowned self] object, change in
            self.loadLoudspeakers()
        }
        let selectedLoudspeakerIndexPath = \AcousmoniumFile.selectedLoudspeakerIndex
        self.selectedLoudspeakerIndexObservation = self.acousmoniumFile.observe(selectedLoudspeakerIndexPath) { [unowned self] object, change in
            for subview in self.subviews {
                subview.setNeedsDisplay(subview.bounds)
            }
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
        for subview in self.subviews { //Update colors
            subview.setNeedsDisplay(subview.bounds)
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
    
    func loadImage() {
        if let acousmoniumFile = self.acousmoniumFile, let data = acousmoniumFile.image, let image = NSImage(data: data) {
            if acousmoniumFile.showImage {
                self.ratioSize = image.size
                self.layer?.contents = image
                self.updateSize()
                return
            }
        }
        self.layer?.contents = nil
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
            loudspeaker.acousmoLoudspeaker.x = Float((mouse.x - self.selectedLoudspeaker.position.x  + (refSize / 2)) / self.frame.size.width)
            loudspeaker.acousmoLoudspeaker.y = Float((mouse.y - self.selectedLoudspeaker.position.y + (refSize / 2)) / self.frame.size.height)
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
        self.updateAlpha()
        
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
                if let message = self.windowController.leftViewController.consoleALastMidiMessage {
                    if message.number == self.acousmoLoudspeaker.input && self.value != message.value {
                        self.value = message.value
                    }
                }
            }
        } else if self.acousmoLoudspeaker.console == 1 {
            let consoleBLastMidiMessagePath = \LeftViewController.consoleBLastMidiMessage
            self.valueObservation = self.windowController.leftViewController.observe(consoleBLastMidiMessagePath) { [unowned self] object, change in
                if let message = self.windowController.leftViewController.consoleBLastMidiMessage {
                    if message.number == self.acousmoLoudspeaker.input && self.value != message.value {
                        self.value = message.value
                    }
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
            var x = superview.frame.size.width * CGFloat(self.acousmoLoudspeaker.x)
            var y = superview.frame.size.height * CGFloat(self.acousmoLoudspeaker.y)
            x -= (refSize / 2)
            y -= (refSize / 2)
            let frame = CGRect(x: x, y: y, width: refSize, height: refSize)
            self.frame = frame
        }
        self.updateAlpha()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let superview = self.superview, let acousmoContainer = superview as? AcousmoContainer, let windowController = self.windowController {
            
            context.saveGState()
            var loudspeakerColor = self.windowController.leftViewController.controllerColor(from: self.acousmoLoudspeaker.input, console: self.acousmoLoudspeaker.console)
            if windowController.editAcousmonium {
                if let fistIndex = acousmoContainer.acousmoniumFile.selectedLoudspeakerIndex.first {
                    let loudspeaker = acousmoContainer.subviews[fistIndex]
                    if loudspeaker != self  {
                        loudspeakerColor = NSColor.lightGray
                    }
                }
            }
            context.setFillColor(loudspeakerColor.cgColor)
            context.addEllipse(in: self.bounds)
            context.drawPath(using: .fill)
            context.restoreGState()
        }
    }
    
}
