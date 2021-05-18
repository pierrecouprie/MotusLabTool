//
//  DefaultSettings.swift
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

import Foundation

/// Extensions of files in bundle
struct FileExtension {
    static let motuslab = "motuslab"
    static let event = "event"
    static let data = "data"
    static let json = "json"
    static let txt = "txt"
    static let mp4 = "mp4"
    static let acousmonium = "acousmonium"
    static let waveform = "waveform"
}

/// Last item paths
struct FilePath {
    static let motusLabFile = "motusLabFile"
    static let audio = "audio"
    static let movie = "movie"
    static let midi = "midi"
    static let motuLab = "motuLab"
    static let acousmoniums = "acousmoniums"
    static let playlist = "playlist"
    static let waveforms = "waveforms"
    static let A = "-A"
    static let B = "-B"
    static let C = "-C"
    static let D = "-D"
}

/// Preference keys
struct PreferenceKey {
    
    // Recorder
    static let audioFormat = "audioFormat"
    static let consoleAColor = "consoleAColor"
    static let consoleBColor = "consoleBColor"
    static let consoleCColor = "consoleCColor"
    static let consoleAMapping = "consoleAMapping"
    static let consoleBMapping = "consoleBMapping"
    static let consoleCMapping = "consoleCMapping"
    static let consoleBActivate = "consoleBActivate"
    static let consoleCActivate = "consoleCActivate"
    static let switchPlayMode = "switchPlayMode"
    static let bitDepth = "bitDepth"
    static let sampleRate = "sampleRate"
    static let channelNumber = "channelNumber"
    
    //Playback
    static let movieSync = "movieSync"
    static let moviePredelay = "moviePredelay"
    
    //Record (new preferences in 2.2 version)
    static let movieSize = "movieSize"
    static let movieQuality = "movieQuality"
    
    // Colors
    static let colorMode = "colorMode"
    static let color1 = "color1"
    static let color1Num = "color1Num"
    static let color2 = "color2"
    static let color2Num = "color2Num"
    static let color3 = "color3"
    static let color3Num = "color3Num"
    static let color4 = "color4"
    static let color5 = "color5"
    static let color5Num = "color5Num"
    static let color6 = "color6"
    static let color6Num = "color6Num"
    static let color7 = "color7"
    static let color7Num = "color7Num"
    static let color8 = "color8"
    static let color9 = "color9"
    static let color9Num = "color9Num"
    static let color10 = "color10"
    static let color10Num = "color10Num"
    static let color11 = "color11"
    static let color11Num = "color11Num"
    static let color12 = "color12"
    
    // Player
    static let playTimelineWaveform = "playTimelineWaveform"
    static let playTimelineControllers = "playTimelineControllers"
    static let playTimelineMarkers = "playTimelineMarkers"
    static let playTimelinePlayhead = "playTimelinePlayhead"
    static let playCTRLAlpha = "playCTRLAlpha"
    static let playMarkerColor = "playMarkerColor"
    static let playPlayheadColor = "playPlayheadColor"
    
    // Acousmonium
    static let acousmoShowImage = "acousmoShowImage"
    static let acousmoOpacity = "acousmoOpacity"
    static let acousmoSize = "acousmoSize"
    static let acousmoShowTitles = "acousmoShowTitles"
    
    //Statistics
    static let statisticsShow = "statisticsShow"
    static let statisticsMin = "statisticsMin"
    static let statisticsMax = "statisticsMax"
    static let statisticsAMean = "statisticsAMean"
    static let statisticsQMean = "statisticsQMean"
    static let statisticsVariance = "statisticsVariance"
    static let statisticsFrequency = "statisticsFrequency"
    static let statisticsDuration = "statisticsDuration"
    
    // Other
    static let valueCorrection = "valueCorrection"
    static let usePlaylist = "usePlaylist"
    
}

/// Audio formats
struct AudioFormat {
    static let aac = "m4a"
    static let pcm = "wav"
    static let aif = "aif"
    static let aiff = "aiff"
    static let mp3 = "mp3"
    
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
    static let playlist = "playlist"
}

/// Correction of MIDI value for Yamaha 02r96
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

struct JSONKey {
    static let file_metadata = "file_metadata"
    static let midi_event = "MIDI_events"
}
