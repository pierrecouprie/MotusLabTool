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

let kAcousmoniumLabelSize: CGFloat = 12

/// The main view
///
/// AcousmoniumView
///       |-subview-> AcousmoniumContainer -> CALayer.contents = background image of acousmonium
///       |-subview-> AcousmoniumLoudspeakerView (one for each loudspeaker)
///                              |-subview-> AcousmoniumShapeView -> round shape
///                              |-subview-> AcousmoniumTextView -> title of loudspeaker
///
class AcousmoniumView: NSView {
    
    weak var windowController: WindowController! {
        didSet {
            if self.windowController != nil {
                self.initializeObserver()
            }
        }
    }
    
    @objc dynamic weak var acousmoniumFile: AcousmoniumFile!
    
    var acousmoniumContainer: AcousmoniumContainer!
    
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
            
            // Delete previous acousmonium
            if self.acousmoniumContainer != nil {
                self.acousmoniumContainer.removeFromSuperview()
            }
            
            // Add new acousmonium
            if let acousmoniumFile = self.windowController.selectedAcousmoniumFile {
                self.acousmoniumFile = acousmoniumFile
                self.acousmoniumContainer = AcousmoniumContainer(frame: NSZeroRect, acousmoniumFile: self.acousmoniumFile, windowController: self.windowController)
                self.addSubview(self.acousmoniumContainer)
                self.acousmoniumContainer.updateSize()
                self.acousmoniumContainer.loadImage()
                self.acousmoniumContainer.loadLoudspeakers()
            } else {
                self.acousmoniumContainer = nil
            }
            
        }
    }
    
}

/// This view contains acousmonium
class AcousmoniumContainer: NSView {
    
    weak var windowController: WindowController!
    @objc dynamic weak var acousmoniumFile: AcousmoniumFile!
    
    var ratioSize = CGSize(width: 300, height: 400)
    
    var acousmoOpacity: Float = 0.8 {
        didSet {
            self.updateLoudspeakerOpacity()
        }
    }
    var labelVisibility: Bool = false {
           didSet {
               self.updateLoudspeakerLabelVisibility()
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
    
    var selectedLoudspeaker: (loudspeaker: AcousmoniumLoudspeakerView?, position: CGPoint) = (nil,NSZeroPoint)
    
    init(frame frameRect: NSRect, acousmoniumFile: AcousmoniumFile, windowController: WindowController) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        self.acousmoniumFile = acousmoniumFile
        self.windowController = windowController
        
        // Initialize observers
        let showImagePath = \AcousmoniumFile.showImage
        self.showImageObservation = self.acousmoniumFile.observe(showImagePath) { [unowned self] object, change in
            self.loadImage()
        }
        let imagePath = \AcousmoniumFile.image
        self.imageObservation = self.acousmoniumFile.observe(imagePath) { [unowned self] object, change in
            self.loadImage()
        }
        let loudspeakersPath = \AcousmoniumFile.acousmoniumLoudspeakers
        self.hpObservation = self.acousmoniumFile.observe(loudspeakersPath) { [unowned self] object, change in
            self.loadLoudspeakers()
        }
        let selectedLoudspeakerIndexPath = \AcousmoniumFile.selectedLoudspeakerIndex
        self.selectedLoudspeakerIndexObservation = self.acousmoniumFile.observe(selectedLoudspeakerIndexPath) { [unowned self] object, change in
            for subview in self.subviews {
                subview.setNeedsDisplay(subview.bounds)
            }
        }
        
        // Add observer to detect preferences properties
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
        let labelVisibility = UserDefaults.standard.bool(forKey: PreferenceKey.acousmoShowTitles)
        if self.labelVisibility != labelVisibility {
            self.labelVisibility = labelVisibility
        }
        let size = UserDefaults.standard.float(forKey: PreferenceKey.acousmoSize)
        if self.acousmoSize != size {
            self.acousmoSize = size
        }
        for subview in self.subviews { //Update colors
            subview.setNeedsDisplay(subview.bounds)
        }
    }
    
    /// update the size of frame if superview is resized
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        self.updateSize()
    }
    
    /// Update size of view proportionaly to ratioSize
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
    
    /// Load image in the contents of CALayer
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
    
    /// When list of loudspeaker is changed, this function update subviews
    func loadLoudspeakers() {
        
        // Add missing loudspeakers
        for loudspeaker in self.acousmoniumFile.acousmoniumLoudspeakers {
            if self.subviews.filter( { ($0 as! AcousmoniumLoudspeakerView).acousmoniumLoudspeaker == loudspeaker } ).count == 0 {
                self.createLoudspeaker(loudspeaker)
            }
        }
        
        // Delete removed loudspeaker
        for subview in self.subviews {
            if let acousmoniumLoudspeaker = (subview as! AcousmoniumLoudspeakerView).acousmoniumLoudspeaker {
                if !self.acousmoniumFile.acousmoniumLoudspeakers.contains(acousmoniumLoudspeaker) {
                    subview.removeFromSuperview()
                    break
                }
            }
        }
    }
    
    /// Create a new loudspeaker (subview)
    func createLoudspeaker(_ acousmoniumLoudspeaker: AcousmoniumLoudspeaker) {
        let defaultFrame = CGRect(x: self.bounds.midX, y: self.bounds.midY, width: self.bounds.size.width * CGFloat(self.acousmoSize), height: self.bounds.size.height * CGFloat(self.acousmoSize))
        let acousmoniumLoudspeakerView = AcousmoniumLoudspeakerView(frame: defaultFrame, acousmoniumLoudspeaker: acousmoniumLoudspeaker, windowController: self.windowController)
        self.addSubview(acousmoniumLoudspeakerView)
        acousmoniumLoudspeakerView.updateAlpha()
        acousmoniumLoudspeakerView.updateLabelVisibility()
        acousmoniumLoudspeakerView.updateFrame()
        acousmoniumLoudspeakerView.updateObserver()
    }
    
    func updateLoudspeakerOpacity() {
        for subview in self.subviews {
            (subview as! AcousmoniumLoudspeakerView).updateAlpha()
        }
    }
    
    func updateLoudspeakerLabelVisibility() {
        for subview in self.subviews {
            (subview as! AcousmoniumLoudspeakerView).updateLabelVisibility()
        }
    }
    
    func updateLoudspeakerSize() {
        for subview in self.subviews {
            (subview as! AcousmoniumLoudspeakerView).updateFrame()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.selectedLoudspeaker.loudspeaker = nil
        
        if !self.windowController.editAcousmonium {
            return
        }
        
        let mouse = self.convert(event.locationInWindow, from: nil)
        
        for subview in self.subviews {
            if NSPointInRect(mouse, subview.frame) {
                let position = CGPoint(x: mouse.x - subview.frame.origin.x, y: mouse.y - subview.frame.origin.y)
                self.selectedLoudspeaker = (subview as? AcousmoniumLoudspeakerView, position)
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let loudspeaker = self.selectedLoudspeaker.loudspeaker {
            let mouse = self.convert(event.locationInWindow, from: nil)
            let refSize = self.frame.size.width * CGFloat(self.acousmoSize)
            loudspeaker.acousmoniumLoudspeaker.x = Float((mouse.x - self.selectedLoudspeaker.position.x  + (refSize / 2)) / self.frame.size.width)
            loudspeaker.acousmoniumLoudspeaker.y = Float((mouse.y - self.selectedLoudspeaker.position.y + (refSize / 2)) / self.frame.size.height)
            loudspeaker.updateFrame()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        self.selectedLoudspeaker.loudspeaker = nil
        self.windowController.saveAcousmoniumFile(self.windowController.selectedAcousmoniumFile)
    }
    
}

/// This view represent a loudspeaker
class AcousmoniumLoudspeakerView: NSView {
    
    weak var windowController: WindowController!
    weak var acousmoniumLoudspeaker: AcousmoniumLoudspeaker!
    var value: Int = 0 {
        didSet {
            self.updateSize(self.value)
        }
    }
    
    var acousmoniumShapeView: AcousmoniumShapeView!
    var acousmoniumTextView: AcousmoniumTextView!
    
    var mouseClic = CGPoint(x: -1, y: -1)
    
    var consoleObservation: NSKeyValueObservation?
    var inputObservation: NSKeyValueObservation?
    var valueObservation: NSKeyValueObservation?
    var editObservation: NSKeyValueObservation?
    
    init(frame frameRect: NSRect, acousmoniumLoudspeaker: AcousmoniumLoudspeaker, windowController: WindowController) {
        super.init(frame: frameRect)
        self.acousmoniumLoudspeaker = acousmoniumLoudspeaker
        self.windowController = windowController
        
        //Create subviews
        self.acousmoniumShapeView  = AcousmoniumShapeView(frame: frameRect, acousmoniumLoudspeaker: acousmoniumLoudspeaker, windowController: windowController)
        self.addSubview(self.acousmoniumShapeView)
        self.acousmoniumTextView  = AcousmoniumTextView(frame: frameRect, acousmoniumLoudspeaker: acousmoniumLoudspeaker)
        self.addSubview(self.acousmoniumTextView)
        self.acousmoniumTextView.addInViewConstraints(superView: self)
        
        //Observers
        let consolePath = \AcousmoniumLoudspeaker.console
        self.consoleObservation = self.acousmoniumLoudspeaker.observe(consolePath) { [unowned self] object, change in
            self.updateObserver()
        }
        
        let inputPath = \AcousmoniumLoudspeaker.input
        self.inputObservation = self.acousmoniumLoudspeaker.observe(inputPath) { [unowned self] object, change in
            self.updateObserver()
        }
        
        let editPath = \WindowController.editAcousmonium
        self.editObservation = self.windowController.observe(editPath) { [unowned self] object, change in
            self.updateFrame()
            self.updateSize(self.value)
            //self.acousmoniumShapeView.setNeedsDisplay(self.acousmoniumShapeView.bounds)
        }
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func updateObserver() {
        if self.acousmoniumLoudspeaker.console == 0 {
            let consoleALastMidiMessagePath = \LeftViewController.consoleALastMidiMessage
            self.valueObservation = self.windowController.leftViewController.observe(consoleALastMidiMessagePath) { [unowned self] object, change in
                if let message = self.windowController.leftViewController.consoleALastMidiMessage {
                    if message.number == self.acousmoniumLoudspeaker.input && self.value != message.value {
                        self.value = message.value
                    }
                }
            }
        } else if self.acousmoniumLoudspeaker.console == 1 {
            let consoleBLastMidiMessagePath = \LeftViewController.consoleBLastMidiMessage
            self.valueObservation = self.windowController.leftViewController.observe(consoleBLastMidiMessagePath) { [unowned self] object, change in
                if let message = self.windowController.leftViewController.consoleBLastMidiMessage {
                    if message.number == self.acousmoniumLoudspeaker.input && self.value != message.value {
                        self.value = message.value
                    }
                }
            }
        } else if self.acousmoniumLoudspeaker.console == 2 {
            let consoleCLastMidiMessagePath = \LeftViewController.consoleCLastMidiMessage
            self.valueObservation = self.windowController.leftViewController.observe(consoleCLastMidiMessagePath) { [unowned self] object, change in
                if let message = self.windowController.leftViewController.consoleCLastMidiMessage {
                    if message.number == self.acousmoniumLoudspeaker.input && self.value != message.value {
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
        if let superview = self.superview, let acousmoniumContainer = superview as? AcousmoniumContainer {
            if self.acousmoniumShapeView.alphaValue != CGFloat(acousmoniumContainer.acousmoOpacity) {
                self.acousmoniumShapeView.alphaValue = CGFloat(acousmoniumContainer.acousmoOpacity)
            }
        }
    }
    
    func updateLabelVisibility() {
        if let superview = self.superview, let acousmoniumContainer = superview as? AcousmoniumContainer {
            self.acousmoniumTextView.isHidden = !acousmoniumContainer.labelVisibility
        }
    }
    
    func updateFrame() {
        if let superview = self.superview, let acousmoniumContainer = superview as? AcousmoniumContainer {
            let refSize = superview.frame.size.width * CGFloat(acousmoniumContainer.acousmoSize)
            var x = superview.frame.size.width * CGFloat(self.acousmoniumLoudspeaker.x)
            var y = superview.frame.size.height * CGFloat(self.acousmoniumLoudspeaker.y)
            x -= (refSize / 2)
            y -= (refSize / 2)
            let frame = CGRect(x: x, y: y, width: refSize, height: refSize)
            self.frame = frame
        }
        self.updateSize(self.value)
    }
    
    func updateSize(_ value: Int) {
        if let acousmoniumShapeView = self.acousmoniumShapeView {
            acousmoniumShapeView.updateSize(value)
        }
    }
    
}

class AcousmoniumShapeView: NSView {
    
    weak var windowController: WindowController!
    weak var acousmoniumLoudspeaker: AcousmoniumLoudspeaker!
    
    init(frame frameRect: NSRect, acousmoniumLoudspeaker: AcousmoniumLoudspeaker, windowController: WindowController) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.windowController = windowController
        self.acousmoniumLoudspeaker = acousmoniumLoudspeaker
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateSize(_ value: Int) {
        if let superview = self.superview, let acousmoniumLoudspeakerView = superview as? AcousmoniumLoudspeakerView {
            var size: CGFloat = CGFloat(Float(value) / 128)
            if self.windowController.editAcousmonium {
                size = 1
            }
            var sizedFrame = acousmoniumLoudspeakerView.frame
            sizedFrame.size.width *= size
            sizedFrame.size.height *= size
            sizedFrame.origin.x = (acousmoniumLoudspeakerView.frame.width  - sizedFrame.size.width) / 2
            sizedFrame.origin.y = (acousmoniumLoudspeakerView.frame.height  - sizedFrame.size.height) / 2
            self.frame = sizedFrame
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let superview = self.superview, let acousmoniumLoudspeakerView = superview as? AcousmoniumLoudspeakerView, let acousmoniumContainer = acousmoniumLoudspeakerView.superview as? AcousmoniumContainer, let windowController = self.windowController {
            
            //Draw circle
            context.saveGState()
            var loudspeakerColor = windowController.leftViewController.controllerColor(from: self.acousmoniumLoudspeaker.input, console: self.acousmoniumLoudspeaker.console)
            if windowController.editAcousmonium {
                if let fistIndex = acousmoniumContainer.acousmoniumFile.selectedLoudspeakerIndex.first {
                    let loudspeaker = acousmoniumContainer.subviews[fistIndex]
                    if loudspeaker != self  {
                        loudspeakerColor = NSColor.lightGray
                    }
                }
            }
            context.setFillColor(loudspeakerColor.cgColor)
            context.addEllipse(in: self.bounds)
            context.drawPath(using: .fill)
            context.restoreGState()
            
            //Draw cross
            if windowController.editAcousmonium {
                let factor = self.bounds.size.width * 0.45
                let smallBounds = self.bounds.insetBy(dx: factor, dy: factor)
                context.saveGState()
                context.setStrokeColor(NSColor.black.cgColor)
                context.setLineWidth(1)
                context.move(to: CGPoint(x: smallBounds.minX, y: smallBounds.minY))
                context.addLine(to: CGPoint(x: smallBounds.maxX, y: smallBounds.maxY))
                context.move(to: CGPoint(x: smallBounds.maxX, y: smallBounds.minY))
                context.addLine(to: CGPoint(x: smallBounds.minX, y: smallBounds.maxY))
                context.drawPath(using: .stroke)
                context.restoreGState()
            }
        }
    }
}

class AcousmoniumTextView: NSView {
    
    weak var windowController: WindowController!
    weak var acousmoniumLoudspeaker: AcousmoniumLoudspeaker!
    
    var titleObservation: NSKeyValueObservation?
    
    init(frame frameRect: NSRect, acousmoniumLoudspeaker: AcousmoniumLoudspeaker) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.acousmoniumLoudspeaker = acousmoniumLoudspeaker
        
        let titlePath = \AcousmoniumLoudspeaker.title
        self.titleObservation = self.acousmoniumLoudspeaker.observe(titlePath) { [unowned self] object, change in
            self.setNeedsDisplay(self.bounds)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext, let acousmoniumLoudspeaker = self.acousmoniumLoudspeaker {
            
            guard acousmoniumLoudspeaker.title != nil else {
                return
            }
            
            context.saveGState()
            
            let font = NSFont.systemFont(ofSize: kAcousmoniumLabelSize)
            
            let textStyle = NSMutableParagraphStyle()
            textStyle.alignment = .center
            
            let textFontAttributes = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: NSColor.red,
                NSAttributedString.Key.paragraphStyle: textStyle
                ] as [NSAttributedString.Key : Any]
            
            var textRect = self.bounds
            let textTextHeight: CGFloat = acousmoniumLoudspeaker.title.boundingRect(with: NSSize(width: textRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes).height
            textRect = NSRect(x: textRect.minX, y: textRect.minY + (frame.size.height - textTextHeight) / 2, width: textRect.width, height: textTextHeight)
            self.bounds.clip()
            acousmoniumLoudspeaker.title.draw(in: textRect.offsetBy(dx: 0, dy: 0.5), withAttributes: textFontAttributes)
            
            context.restoreGState()
            
        }
    }
    
}
