//
//  Statistics.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 13/09/2019.
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

class Statistics: NSObject {
    
    var midiControllerEvents: [MIDIControllerEvent]!
    var duration: Float = 0
    
    var consoleAControllerValues: [[Int]]!
    var consoleBControllerValues: [[Int]]!
    
    var consoleAmin: [Float]!
    var consoleBmin: [Float]!
    var consoleAmax: [Float]!
    var consoleBmax: [Float]!
    var consoleAarithmeticMean: [Float]!
    var consoleBarithmeticMean: [Float]!
    var consoleAquadraticMean: [Float]!
    var consoleBquadraticMean: [Float]!
    var consoleAvariance: [Float]!
    var consoleBvariance: [Float]!
    var consoleAdurations: [Float]!
    var consoleBdurations: [Float]!
    var consoleAfrequency: [Float]!
    var consoleBfrequency: [Float]!
    
    init(_ midiControllerEvents: [MIDIControllerEvent], duration: Float) {
        super.init()
        self.midiControllerEvents = midiControllerEvents
        self.duration = duration
    }
    
    func compute() {
        
        guard self.midiControllerEvents != nil && self.midiControllerEvents.count > 0 else {
            return
        }
        
        //Parse values
        self.consoleAControllerValues = [[Int]](repeating: [], count: 129)
        self.consoleBControllerValues = [[Int]](repeating: [], count: 129)
        
        for event in self.midiControllerEvents {
            if event.console == 0 {
                self.consoleAControllerValues[event.number].append(event.value)
            } else {
                self.consoleBControllerValues[event.number].append(event.value)
            }
        }
        
        //Compute
        self.consoleAmin = [Float](repeating: 0, count: 129)
        self.consoleBmin = [Float](repeating: 0, count: 129)
        self.consoleAmax = [Float](repeating: 0, count: 129)
        self.consoleBmax = [Float](repeating: 0, count: 129)
        self.consoleAarithmeticMean = [Float](repeating: 0, count: 129)
        self.consoleBarithmeticMean = [Float](repeating: 0, count: 129)
        self.consoleAquadraticMean = [Float](repeating: 0, count: 129)
        self.consoleBquadraticMean = [Float](repeating: 0, count: 129)
        self.consoleAvariance = [Float](repeating: 0, count: 129)
        self.consoleBvariance = [Float](repeating: 0, count: 129)
        self.consoleAdurations = [Float](repeating: 0, count: 129)
        self.consoleBdurations = [Float](repeating: 0, count: 129)
        self.consoleAfrequency = [Float](repeating: 0, count: 129)
        self.consoleBfrequency = [Float](repeating: 0, count: 129)
        
        for n in 1..<129 {
            
            if let min = self.consoleAControllerValues[n].min() {
                self.consoleAmin[n] = Float(min)
            }
            if let min = self.consoleBControllerValues[n].min() {
                self.consoleBmin[n] = Float(min)
            }
            
            if let max = self.consoleAControllerValues[n].max() {
                self.consoleAmax[n] = Float(max)
            }
            if let max = self.consoleBControllerValues[n].max() {
                self.consoleBmax[n] = Float(max)
            }
            
            self.consoleAarithmeticMean[n] = Float(self.consoleAControllerValues[n].reduce(0, +)) / Float(self.consoleAControllerValues[n].count)
            self.consoleBarithmeticMean[n] = Float(self.consoleBControllerValues[n].reduce(0, +)) / Float(self.consoleBControllerValues[n].count)
            
            self.consoleAquadraticMean[n] = sqrtf(self.consoleAControllerValues[n].reduce(Float(0), { $0 + powf(Float($1),2) } ) / Float(self.consoleAControllerValues[n].count))
            self.consoleBquadraticMean[n] = sqrtf(self.consoleBControllerValues[n].reduce(Float(0), { $0 + powf(Float($1),2) } ) / Float(self.consoleBControllerValues[n].count))
            
            self.consoleAvariance[n] = self.consoleAControllerValues[n].reduce(Float(0), { $0 + powf(Float($1) - self.consoleAarithmeticMean[n], 2) } ) / Float(self.consoleAControllerValues[n].count)
            self.consoleBvariance[n] = self.consoleBControllerValues[n].reduce(Float(0), { $0 + powf(Float($1) - self.consoleBarithmeticMean[n], 2) } ) / Float(self.consoleBControllerValues[n].count)
            
            var events = self.midiControllerEvents.filter( { $0.number == n && $0.console == 0} )
            var tempDate = Float(0)
            self.consoleAdurations[n] = events.reduce(Float(0), { duration, event in
                if event.value > 10 {
                    let interval = event.date - tempDate
                    tempDate = event.date
                    return duration + interval
                }
                return duration
            })
            self.consoleAfrequency[n] =  Float(events.count) / self.duration
            
            events = self.midiControllerEvents.filter( { $0.number == n && $0.console == 1} )
            tempDate = Float(0)
            self.consoleBdurations[n] = events.reduce(Float(0), { duration, event in
                if event.value > 10 {
                    let interval = event.date - tempDate
                    tempDate = event.date
                    return duration + interval
                }
                return duration
            })
            self.consoleBfrequency[n] = Float(events.count) / self.duration
            
        }
        
    }
    
}
