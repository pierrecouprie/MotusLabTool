//
//  MotusLabToolUnitTests.swift
//  MotusLabToolUnitTests
//
//  Created by Pierre Couprie on 15/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import XCTest
@testable import MotusLabTool

class MotusLabToolUnitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMIDIValueCorrection() {
        var tempValue: Int = 0
        for n in 0..<127 {
            let result = MIDIValueCorrection(n, type: 1)
            XCTAssertTrue(result > -1 && result < 128, "result: \(result)")
            XCTAssertTrue(result >= tempValue, "result: \(result) tempValue: \(tempValue)")
            tempValue = result
        }
    }
    
    func testFloatToTime() {
        var value: Float = 67.857
        var result = value.floatToTime()
        XCTAssertEqual(result, "01:07.857")
        
        value = 0
        result = value.floatToTime()
        XCTAssertEqual(result, "00:00.000")
        
        value = Float.nan
        result = value.floatToTime()
        XCTAssertEqual(result, "00:00.000")
    }
    
    func testFloatToTimeSeconds() {
        var value: Float = 67.857
        var result = value.floatToTimeSeconds()
        XCTAssertEqual(result, "01:07")
        
        value = 0
        result = value.floatToTimeSeconds()
        XCTAssertEqual(result, "00:00")
        
        value = Float.nan
        result = value.floatToTimeSeconds()
        XCTAssertEqual(result, "00:00")
    }
    
    func testStringToTime() {
        var time = "01:47:981"
        var result = time.stringToTime()
        XCTAssertEqual(result, 107)
        
        time = "01:4"
        result = time.stringToTime()
        XCTAssertEqual(result, 64)
        
        time = "8.567"
        result = time.stringToTime()
        XCTAssertEqual(result, 8.567)
        
        time = "01:47.981"
        result = time.stringToTime()
        XCTAssertEqual(result, 107.981)
    }
    
    func testFloatStringTime() {
        for _ in 0..<100 {
            let time = Float.random(in: 0...3600)
            let stringValue = time.floatToTime()
            let returnTime = stringValue.stringToTime()
            XCTAssertEqual(time, returnTime, accuracy: 0.001)
        }
    }
    
    func testDecibel() {
        for _ in 0..<1000 {
            let value = Float.random(in: 0...1)
            let result = value.decibel
            XCTAssertLessThanOrEqual(result, 0)
            XCTAssertGreaterThanOrEqual(result, -160)
        }
    }
    
    func testDataColor() {
        for _ in 0..<100 {
            let color = NSColor(calibratedRed: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: CGFloat.random(in: 0...1))
            let colorData = color.data
            let dataColor = colorData.color
            XCTAssertEqual(color, dataColor)
        }
    }
    
    func testMotusLabToolVersion() {
        let version = String.motusLabToolVersion
        XCTAssertNotEqual(version, "")
    }
    
    func testUrlFileName() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        var url = URL(fileURLWithPath: paths[0]).appendingPathComponent("test").appendingPathComponent("test2")
        XCTAssertEqual(url.fileName, "test2")
        url = url.appendingPathExtension("ext")
        XCTAssertEqual(url.fileName, "test2")
    }
    
    func testMarkerCountValueTransformer() {
        let markerCountValueTransformer = MarkerCountValueTransformer()
        var result = markerCountValueTransformer.transformedValue(Int(1)) as! String
        XCTAssertEqual(result, "1 marker")
        result = markerCountValueTransformer.transformedValue(Int(3)) as! String
        XCTAssertEqual(result, "3 markers")
    }
    
    func testAddLoudspeaker() {
        let acousmonium = AcousmoniumFile(name: "test")
        acousmonium.createLoudspeaker()
        XCTAssertEqual(acousmonium.acousmoniumLoudspeakers.count, 1)
    }
    
    func testAddSession() {
        let file = MotusLabFile(name: "test")
        let _ = file.createSession()
        XCTAssertEqual(file.sessions.count, 1)
    }
    
    func testAddMarker() {
        let file = MotusLabFile(name: "test")
        let session = file.createSession()
        let  marker = Marker(title: "test", date: 1.876)
        session.addMarker(marker)
        XCTAssertEqual(session.markers.count, 1)
    }
    
    func testStringSize() {
        let playTimeRuler = PlayTimeRulerView()
        let size = playTimeRuler.stringSize("O")
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }
    
    func testCleanMidiControlList() {
        var values = [(input: String, output: String)]()
        values.append(("1 2","1-2"))
        values.append(("1 2 3","1-3"))
        values.append(("1 2 3 5","1-3 5"))
        values.append(("1 3 4 5","1 3-5"))
        values.append(("1 2 3 5 6 7","1-3 5-7"))
        values.append(("1 2 3 5 7 8 9","1-3 5 7-9"))
        values.append(("1 3 4 5 7 9 10 11 12 14","1 3-5 7 9-12 14"))
        values.append(("1 3 4 5 7 8 9 13 14 14 15 16 17 17","1 3-5 7-9 13-17"))
        values.append(("1 3 4 5 7 8 9 10 11 12 13 14 14 15 16 17 17","1 3-5 7-17"))
        
        let windowController = WindowController()
        let midiParameters = MIDIParameters(console: 0, windowController: windowController)
        for item in values {
            var filterControllers = [Bool](repeating: false, count: 129)
            let itemArray = item.input.components(separatedBy: " ")
            for index in itemArray {
                filterControllers[Int(index)!] = true
            }
            
            let result = midiParameters.cleanMidiControlList(filterControllers)
            XCTAssertEqual(result, item.output, "result: " + result + " and expected: " + item.output)
        }
        
    }

}
