//
//  AudioAnalyzer.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 01/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//

import Foundation
import Accelerate
import AudioToolbox
import AVFoundation

let kWaveformPrecision: Int = 700

class AudioAnalyzer: NSObject {
    
    var url: URL!
    
    init(_ url: URL) {
        super.init()
        self.url = url
    }
    
    func computeChannelsData() -> [[Float]]? {
        
        var result = [[Float]]()
        
        //Open audio File
        var af: ExtAudioFileRef? = nil
        var err: OSStatus = ExtAudioFileOpenURL(self.url as CFURL, &af)
        if err != noErr {
            Swift.print("AudioAnalyzer: computeChannelsData -> Could not resolve URL (\(String(describing: url)))!")
            return nil
        }
        
        //allocate an empty ASBD
        var fileASBD = AudioStreamBasicDescription()
        
        //get the ASBD from the file
        var fileSize = UInt32(MemoryLayout.size(ofValue: fileASBD))
        err = ExtAudioFileGetProperty(af!, kExtAudioFileProperty_FileDataFormat, &fileSize, &fileASBD)
        if err != noErr {
            Swift.print("AudioAnalyzer: computeChannelsData -> Could not get Audio File Format!")
            return nil
        }
        
        let asset:AVAsset = AVAsset.init(url: url)
        let sampleRate = fileASBD.mSampleRate
        let channelCount = fileASBD.mChannelsPerFrame
        
        var clientASBD = AudioStreamBasicDescription()
        clientASBD.mSampleRate = 44100
        clientASBD.mFormatID = kAudioFormatLinearPCM
        clientASBD.mFormatFlags = kAudioFormatFlagIsFloat
        clientASBD.mBytesPerPacket = 4 * channelCount
        clientASBD.mFramesPerPacket = 1
        clientASBD.mBytesPerFrame = 4 * channelCount
        clientASBD.mChannelsPerFrame = channelCount
        clientASBD.mBitsPerChannel = 32
        
        //set the ASBD to be used
        var clientSize = UInt32(MemoryLayout.size(ofValue: clientASBD))
        err = ExtAudioFileSetProperty(af!, kExtAudioFileProperty_ClientDataFormat, clientSize, &clientASBD)
        if err != noErr {
            Swift.print("AudioAnalyzer: computeChannelsData -> Could not set Audio File Format!")
            return nil
        }
        
        //check the number of frames expected
        var numberOfFrames: Int64 = 0
        var propertySize = UInt32(MemoryLayout<Int64>.size)
        err = ExtAudioFileGetProperty(af!, kExtAudioFileProperty_FileLengthFrames, &propertySize, &numberOfFrames)
        if err != noErr {
            Swift.print("AudioAnalyzer: computeChannelsData -> Could not get Audio File Size!")
            return nil
        }
        //Correct number of frame expected to be in 44100
        numberOfFrames = (numberOfFrames * 44100) / Int64(sampleRate)
        
        //initialize a buffer and a place to put the final data
        let bufferFrames = 4096
        var finalData = UnsafeMutablePointer<Float>.allocate(capacity: Int(numberOfFrames) * Int(channelCount) * MemoryLayout<Float>.size)
        defer {
            //finalData.deallocate(capacity: Int(numberOfFrames) * Int(channelCount) * MemoryLayout<Float>.size)
            finalData.deallocate()
        }
        
        //pack all this into a buffer list
        var bufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(MemoryLayout<Float>.size * bufferFrames),
                mData: finalData
            )
        )
        
        //read the data
        var count: UInt32 = 0
        var ioFrames: UInt32 = UInt32(bufferFrames)
        while ioFrames > 0 {
            
            err = ExtAudioFileRead(af!, &ioFrames, &bufferList)
            if err != noErr {
                Swift.print("AudioAnalyzer: computeChannelsData -> Error reading Audio Data!")
                return nil
            }
            
            count += ioFrames
            
            bufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 1,
                    mDataByteSize: UInt32(MemoryLayout<Float>.size * bufferFrames),
                    mData: finalData + (Int(count) * Int(channelCount))
                )
            )
            
        }
        
        var outputData: [Float] = Array(UnsafeMutableBufferPointer(start: finalData, count: Int(numberOfFrames) * Int(channelCount)))
        
        //dispose of the file
        err = ExtAudioFileDispose(af!)
        if err != noErr {
            Swift.print("AudioAnalyzer: computeChannelsData -> An unknown error has occurred!")
            return nil
        }
        
        //Uninterlace channels
        let numFrames = outputData.count
        if channelCount == 1 {
            result.append(outputData)
        } else {
            let channelFrame = numFrames/Int(channelCount)
            for channel in 0..<channelCount {
                var channelResult = [Float](repeating : 0.0, count : channelFrame)
                var zero: Float = 0.0
                if channel > 0 {
                    outputData.removeFirst()
                }
                vDSP_vsadd(outputData, vDSP_Stride(channelCount), &zero, &channelResult, 1, vDSP_Length(channelFrame))
                
                result.append(channelResult)
            }
        }
        
        return self.prepareWaveform(result)
        
    }
    
    func prepareWaveform(_ data: [[Float]]) -> [[Float]] {
        
        let serieCount = data.count
        var dataStep = data.first!.count / kWaveformPrecision
        dataStep = dataStep > 0 ? dataStep : 1
        
        var downSampleChannels = [[Float]]()
        
        for n in 0..<serieCount {
            let downSample = self.downsampleMax(data[n], windowSize: dataStep)
            downSampleChannels.append(downSample)
        }
        
        return downSampleChannels
        
    }
    
    /**
     Downsample array with max value
     - parameter data: Input data
     - parameter windowSize: Size of window
     - returns: Output data downsampled
     */
    func downsampleMax(_ data: [Float], windowSize: Int) -> [Float] {
        
        let dataCount = data.count
        if dataCount == 1 {
            return data
        }
        let length: Int = dataCount - windowSize
        var maxBuffer = [Float](repeating : 0.0, count : length)
        vDSP_vswmax(data, 1, &maxBuffer, 1, vDSP_Length(length), vDSP_Length(windowSize))
        
        let downsampledLength = dataCount / Int(windowSize)
        var resultBuffer = [Float](repeating : 0.0, count : downsampledLength)
        var zero: Float = 0.0
        vDSP_vsadd(maxBuffer, vDSP_Stride(windowSize), &zero, &resultBuffer, 1, vDSP_Length(downsampledLength))
        
        return resultBuffer
    }
    
}