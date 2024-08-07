//
//  MCRemote.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 06/08/2024.
//  Copyright © 2024 Pierre Couprie. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MCRemoteType {
    func receiveData(_ dictionary: [String: Any])
}

class MCRemote: NSObject, MCSessionDelegate {

    var delegate: MCRemoteType!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var isWorking: Bool = false
    
    init(delegate: MCRemoteType) {
        super.init()
        
        self.delegate = delegate
        
        self.peerID = MCPeerID(displayName: Host.current().name ?? kMCRemoteId)
        self.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.mcSession.delegate = self
    }
    
    func startHostRemote() {
        self.hostSession()
        self.isWorking = true
    }
    
    func endHostRemote() {
        self.mcAdvertiserAssistant.stop()
        self.isWorking = false
    }
    
    func hostSession() {
        self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: kMCRemoteId, discoveryInfo: nil, session: self.mcSession)
        self.mcAdvertiserAssistant.start()
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("MCRemote: session() Connected: \(peerID.displayName)")
        case .connecting:
            print("MCRemote: session() Connecting: \(peerID.displayName)")
        case .notConnected:
            print("MCRemote: session() Not Connected: \(peerID.displayName)")
        @unknown default:
            print("MCRemote: session() Fatal error")
        }
    }
    
    func sendRemote(_ action: String, value: Any) {
        let dict = [action: value]
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false)
            try self.mcSession.send(data, toPeers: self.mcSession.connectedPeers, with: .unreliable)
        } catch let error as NSError {
            Swift.print("MCRemote: sendRemote() Error create or send data, " + error.localizedDescription)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [unowned self] in
            
            do {
                let dictionary = try NSKeyedUnarchiver.unarchive(data: data, of: NSDictionary.self)
                self.delegate.receiveData(dictionary as! [String : Any])
            } catch let error as NSError {
                print("MCRemote: session() Error to unarchive data, " + error.localizedDescription)
            }
            
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
}
