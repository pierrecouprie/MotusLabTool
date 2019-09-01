//
//  DefaultSettings.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 28/08/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation

struct FileExtension {
    static let motuslab = "motuslab"
    static let event = "event"
    static let data = "data"
    static let json = "json"
    static let mp4 = "mp4"
    static let acousmonium = "acousmonium"
}

struct FilePath {
    static let motusLabFile = "motusLabFile"
    static let audio = "audio"
    static let movie = "movie"
    static let midi = "midi"
    static let motuLab = "motuLab"
    static let acousmoniums = "acousmoniums"
}

struct PreferenceKey {
    
    //Recorder
    static let audioFormat = "audioFormat"
    static let consoleAColor = "consoleAColor"
    static let consoleBColor = "consoleBColor"
    static let consoleAMapping = "consoleAMapping"
    static let consoleBMapping = "consoleBMapping"
    static let consoleBActivate = "consoleBActivate"
    static let switchPlayMode = "switchPlayMode"
    
    //Colors
    static let colorMode = "colorMode"
    static let color1 = "color1"
    static let color2 = "color2"
    static let color3 = "color3"
    static let color4 = "color4"
    static let color5 = "color5"
    static let color6 = "color6"
    static let color7 = "color7"
    static let color8 = "color8"
    
    //Player
    static let playTimelineWaveform = "playTimelineWaveform"
    static let playTimelineControllers = "playTimelineControllers"
    static let playTimelineMarkers = "playTimelineMarkers"
    static let playTimelinePlayhead = "playTimelinePlayhead"
    static let playCTRLAlpha = "playCTRLAlpha"
    static let playMarkerColor = "playMarkerColor"
    static let playPlayheadColor = "playPlayheadColor"
    
    //Acousmonium
    static let acousmoShowImage = "acousmoShowImage"
    static let acousmoOpacity = "acousmoOpacity"
    static let acousmoSize = "acousmoSize"
    static let acousmoShowTitles = "acousmoShowTitles"
    
    //Other
    static let valueCorrection = "valueCorrection"
    
}

struct AudioFormat {
    static let aac = "m4a"
    static let pcm = "wav"
    
    static func typeFrom(_ tag: Int) -> String {
        switch tag {
        case 0:
            return AudioFormat.aac
        default:
            break
        }
        return AudioFormat.pcm
    }
    
    static func tagFrom(_ type: String) -> Int {
        switch type {
        case AudioFormat.aac:
            return 0
        default:
            break
        }
        return 1
    }
}

struct Mode {
    static let none = "none"
    static let recording = "recording"
    static let playing = "playing"
}

func MIDIValueCorrection(_ value: Int, type: Int) -> Int {
    if type == 1 {
        switch value {
        case 0..<16:
            return (value * 6) / 15
        case 16...27:
            return (((value - 16) * 6) / 12) + 7
        case 28...41:
            return (((value - 28) * 10) / 14) + 13
        case 42...58:
            return (((value - 42) * 18) / 17) + 23
        case 59...70:
            return (((value - 59) * 13) / 12) + 41
        case 71...86:
            return (((value - 71) * 18) / 16) + 54
        case 87...104:
            return (((value - 87) * 18) / 18) + 72
        case 105...118:
            return (((value - 105) * 13) / 14) + 90
        case 119...124:
            return (((value - 119) * 13) / 5) + 103
        case 125...126:
            return (((value - 125) * 12) / 2) + 117
        default:
            break
        }
        return 127
    }
    return value
}


