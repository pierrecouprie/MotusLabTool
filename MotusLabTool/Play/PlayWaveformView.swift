//
//  PlayWaveformView.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Cocoa

class PlayWaveformView: NSView {
    
    var waveform: [[Float]]! {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        if let waveform = self.waveform, let context = NSGraphicsContext.current?.cgContext {
            
            let height: CGFloat = self.bounds.size.height / 2 / CGFloat(waveform.count)
            let heightTranslation = height * 2
            
            var yTranslation: CGFloat = height
            for channelWaveform in waveform {
                
                var drawingPath: CGMutablePath = CGMutablePath()
                let curvePath = self.CurvePath(frame: self.bounds, channelWaveform: channelWaveform)
                drawingPath = curvePath as! CGMutablePath
                
                self.drawPath(context: context, curvePath: drawingPath, height: height, yTranslation: yTranslation)
                
                yTranslation += heightTranslation
                
            }
            
        }
        
    }
    
    /**
     Draw a path from a serie
     - parameter context: CGContext
     - parameter curvePath: the path to draw
     - parameter height: the height of view
     - parameter yTranslation: the y center position of serie
     */
    func drawPath(context: CGContext, curvePath: CGPath, height: CGFloat, yTranslation: CGFloat) {
        
        context.saveGState()
        
        let path: CGMutablePath = CGMutablePath()
        
        context.setFillColor(NSColor(named: "waveformColor")!.cgColor)
        context.setStrokeColor(NSColor(named: "waveformColor")!.cgColor)
        context.setLineWidth(1.0)
        context.setLineJoin(CGLineJoin.round)
        
        //Top
        let tTransform = CGAffineTransform.init(translationX: 0, y: yTranslation)
        let sTransform = tTransform.scaledBy(x: 1, y: height)
        path.addPath(curvePath, transform: sTransform)
        
        //Bottom with return
        let t2Transform = CGAffineTransform.init(translationX: 0, y: yTranslation)
        let s2Transform = t2Transform.scaledBy(x: 1, y: -height)
        path.addPath(curvePath, transform: s2Transform)
        
        //Center line
        path.move(to: CGPoint(x: 0, y: yTranslation))
        path.addLine(to: CGPoint(x: self.bounds.size.width, y: yTranslation))
        
        context.addPath(path)
        context.drawPath(using: CGPathDrawingMode.fillStroke)
        
        context.restoreGState()
        
    }
    
    /**
     Create the path to draw from data
     - parameter channel: Channel to draw, nil for mixed channels
     - returns: The path to draw
     */
    func CurvePath(frame: NSRect, channelWaveform: [Float]) -> CGPath {
        
        let dataCountValues = waveform.first!.count
        let width = self.bounds.size.width
        
        var points = [CGPoint]()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var first = true
        
        for (index,value) in channelWaveform.enumerated() {
            
            x = (CGFloat(index) * width) / CGFloat(dataCountValues)
            y = CGFloat(value)
            
            if first {
                first = false
                let cgPoint = CGPoint(x: x, y: 0)
                points.append(cgPoint)
            }
            
            let cgPoint = CGPoint(x: x, y:  y)
            points.append(cgPoint)
            
        }
        
        let cgLastPoint = CGPoint(x: x, y:  0)
        points.append(cgLastPoint)
        let cgFirstPoint = CGPoint(x: 0, y:  0)
        points.insert(cgFirstPoint, at: 0)
        
        let path: CGMutablePath = CGMutablePath()
        path.addLines(between: points)
        
        return path
        
    }
    
}
