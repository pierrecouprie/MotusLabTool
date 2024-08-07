//
//  ViewController.swift
//  MotusLabTool-Remote
//
//  Created by Pierre Couprie on 06/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
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

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var isRecording: Bool = false
    
    @IBOutlet weak var counter: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var vuMeter: VuMeterView!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    internal lazy var aboutViewController: AboutViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
        return viewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize interface
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "macbook.and.iphone"),
                                                                 style: .done,
                                                                 target: self,
                                                                 action: #selector(showConnectionMenu))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(showAboutPage))
        
        // Initialize parameters for hosting session
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.mcSession = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        self.mcSession.delegate = self
    }
    
    /// Display sheet window to initialize connection
    @objc func showConnectionMenu() {
        let mcBrowser = MCBrowserViewController(serviceType: kMCRemoteId, session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    /// Display about sheet window
    @objc func showAboutPage() {
        present(self.aboutViewController, animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("ViewController: session() Connected: \(peerID.displayName)")
        case .connecting:
            print("ViewController: session() Connecting: \(peerID.displayName)")
        case .notConnected:
            print("ViewController: session() Not Connected: \(peerID.displayName)")
        @unknown default:
            print("ViewController: session() Fatal error")
        }
    }
    
    /// Send data to host
    func sendRemote(_ action: String, value: Any) {
        let dict = [action: value]
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false)
            try self.mcSession.send(data, toPeers: self.mcSession.connectedPeers, with: .unreliable)
        } catch let error as NSError {
            Swift.print("ViewController: sendRemote() Error create or send data, " + error.localizedDescription)
        }
    }
    
    /// Receive data from host
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [unowned self] in
            do {
                let dictionary = try NSKeyedUnarchiver.unarchive(data: data, of: NSDictionary.self)
                self.receiveData(dictionary as! [String : Any])
            } catch {
                print("ViewController: session() Error to unarchive data!")
            }
        }
    }
    
    /// Parse data received frome host
    /// - Parameter dictionary: Key (MCRemoteAction) and value(s)
    func receiveData(_ dictionary: [String: Any]) {
        //Swift.print(dictionary)
        for item in dictionary {
            switch item.key {
            case MCRemoteAction.counter:
                if let floatValue = item.value as? Float {
                    self.counter.text = floatValue.floatToTime()
                }
            case MCRemoteAction.vuMeter:
                if let levels = item.value as? NSArray {
                    self.vuMeter.levels = [levels[0] as! Float,levels[1] as! Float]
                }
            case MCRemoteAction.displayMode:
                if let mode = item.value as? Int {
                    self.recordButton.isEnabled = mode == 1 ? true : false
                    self.isRecording = false
                    self.updateRecordButton()
                }
            case MCRemoteAction.recordOff:
                if self.isRecording {
                    self.isRecording = false
                    self.updateRecordButton()
                }
            case MCRemoteAction.recordOn:
                if !self.isRecording {
                    self.isRecording = true
                    self.updateRecordButton()
                }
            default:
                Swift.print("ViewController: ReceiveData() Unable to read incomming data!")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    /// User start or stop recording
    @IBAction func changeRecord(_ sender: Any) {
        if self.isRecording {
            self.isRecording = false
            self.sendRemote(MCRemoteAction.recordOff, value: true)
            self.updateRecordButton()
        } else {
            self.isRecording = true
            self.sendRemote(MCRemoteAction.recordOn, value: true)
            self.updateRecordButton()
        }
    }
    
    /// Update tint of record button
    /// - red: record in progress
    /// - blue: stop
    func updateRecordButton() {
        self.recordButton.tintColor = self.isRecording ? UIColor.red : UIColor.systemBlue
    }


}

