//
//  NetworkSupport.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import Foundation
import MultipeerConnectivity
import os

/// Uniquely identifies the service.
/// Make this unique to avoid interfering with other Multipeer services.
/// Don't forget to update the project Info AND the project Info.plist property lists accordingly.
let serviceType = "l10-004-005-00"

/// This structure is used at setup time to identify client needs to a server.
/// Currently, it only contains an identifying message, but this can be expanded to contain version information and other data.
struct Request: Codable {
    /// An identifying message that is to be transmitted.
    var details: String
}

/// This class deals with matters relating to setting up Server and Client Multipeer services.
class NetworkSupport: NSObject, ObservableObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    /// The local peer identifier
    private var peerID: MCPeerID
    
    /// The current session
    private var session: MCSession
    
    /// For a server, this allows access to the MCNearbyServiceAdvertiser; nil otherwise.
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    /// For a client, this allows access to the MCNearbyServiceBrowser; nil otherwise.
    var nearbyServiceBrowser: MCNearbyServiceBrowser?
    
    /// Contains the list of connected peers.  Used by the client.
    @Published var peers: [MCPeerID] = [MCPeerID]()
    
    /// True if connected to a peer, false otherwise.
    @Published var connected = false
    
    /// Contains the most recent incoming message.
    @Published var incomingMessage = ""
    
    /// Contains the most recent PeerName from incoming message.
    @Published var peerName = ""
    
    /// Contains the board, initialized to all 0's then treasures placed as 1's
    @Published var treasureArray : TreasureBoard = TreasureBoard(numColumns: 10, numRows: 10, numTreasures: 5)
    
    /// Contains the number of treasures
    @Published var numTreasures = 5
    
    /// Contains the description of the client (example: <MCPeerID: 0x600001710890 DisplayName = iPad Pro (9.7-inch)>)
    @Published var player01_name = ""
    @Published var player02_name = ""
    
    /// Contains the scores
    @Published var player01_score = 0
    @Published var player02_score = 0
    
    /// Contains a boolean to determine if its player 1 or player 2's turn
    @Published var isPlayer1Turn : Bool = true
    
    /// Create a Multipeer Server or Client
    /// - Parameter browse: true creates a Client, false creates a Server
    init(browse: Bool) {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        if !browse {
            nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        }
        else {
            nearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        }
        
        super.init()
        
        session.delegate = self
        nearbyServiceAdvertiser?.delegate = self
        nearbyServiceBrowser?.delegate = self
        
        if browse {
            nearbyServiceBrowser?.startBrowsingForPeers()
        }

    }
    
    
    
    
    // MARK: - MCNearbyServiceAdvertiserDelegate Methods. See XCode documentation for details.
    
    /// Inherited from MCNearbyServiceAdvertiserDelegate.advertiser(_:didNotStartAdvertisingPeer:).
    /// Currently only logs.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        os_log("didNotStartAdvertisingPeer \(error.localizedDescription)")
    }
    
    /// Inherited from MCNearbyServiceAdvertiserDelegate.advertiser(_:didReceiveInvitationFromPeer:withContext:invitationHandler:).
    /// Right now, all connection requests are accepted.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        do {
            let request = try JSONDecoder().decode(Request.self, from: context ?? Data())
            os_log("didReceiveInvitationFromPeer \(peerID.displayName) \(request.details)")
            
            invitationHandler(true, self.session)
        }
        catch let error {
            os_log("didReceiveInvitationFromPeer \(error.localizedDescription)")
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate Methods. See XCode documentation for details.
    
    /// Adds the given peer to the peers array.
    /// - Parameter peer: The peer to be added.
    private func addPeer(peer: MCPeerID) {
        DispatchQueue.main.async {
            if !self.peers.contains(peer) {
                os_log("addPeer")
                self.peers.append(peer)
                if (self.peers.count == 1){
                    self.send(message: "You are Player 1 ... waiting for Player 2")
                }
                
                else if (self.peers.count == 2){
                    self.send(message: "Welcome Player 2 ... Start game")
                }
                 
                
            }
            
            if self.peers.count == 2{
                self.player01_name = self.peers[0].description
                self.player02_name = self.peers[1].description
            }
        }
    }
    
    /// Removes the given peer from the peers array, if possible.
    /// - Parameter peer: The peer to be removed.
    private func removePeer(peer: MCPeerID) {
        DispatchQueue.main.async {
            guard let index = self.peers.firstIndex(of: peer) else {
                return
            }
            os_log("removePeer")
            self.peers.remove(at: index)
        }
    }
    
    /// Inherited from MCNearbyServiceBrowserDelegate.browser(_:didNotStartBrowsingForPeers:).
    /// Currently only logs.
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        os_log("didNotStartBrowsingForPeers \(error.localizedDescription)")
    }
    
    /// Inherited from MCNearbyServiceBrowserDelegate.browser(_:foundPeer:withDiscoveryInfo:).
    /// Updates the peers array with the newly-found peerID.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let info2 = info?.description ?? ""
        os_log("foundPeer \(peerID) \(info2)")
        if (peers.count < 2){
            addPeer(peer: peerID)
        }
        else{
            print("Two peers already connected")
        }
        
    }
    
    /// Inherited from MCNearbyServiceBrowserDelegate.browser(_:lostPeer:).
    /// Removes the lost peerID from the peers array and updates connected status.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        os_log("lostPeer \(peerID)")
        removePeer(peer: peerID)
        DispatchQueue.main.async {
            self.connected = false
        }
    }
    
    // MARK: - Client Setup Method
    
    /// Establish a session with a server.
    /// - Parameters:
    ///   - peerID: The peer ID of the server.
    ///   - request: The connection request.  This can contain additional information that can be used by a server to accept or reject a connection.
    func contactPeer(peerID: MCPeerID, request: Request) throws {
        os_log("contactPeer \(peerID) \(request.details)")
        let request = try JSONEncoder().encode(request)
        nearbyServiceBrowser?.invitePeer(peerID, to: session, withContext: request, timeout: TimeInterval(120))
    }
    
    // MARK: - MCSessionDelegate Methods. See XCode documentation for details.
    
    /// Inherited from MCSessionDelegate.session(_:didReceive:fromPeer:).
    /// Updates incomingMessage with the message that was just received
    func session(_ session: MCSession, didReceive: Data, fromPeer: MCPeerID) {
        do {
            let request = try JSONDecoder().decode(String.self, from: didReceive)
            os_log("didReceive \(request) \(fromPeer)")
            
            DispatchQueue.main.async {
                self.incomingMessage = request
                self.peerName = fromPeer.displayName
                
                if self.peers.count == 2{
                    
                    if (self.isPlayer1Turn && self.player01_name == fromPeer.description){
                        self.validateGuess(guess: request, playerId: fromPeer.description, player: 1)
                        self.isPlayer1Turn = false
                    }
                    else if (!self.isPlayer1Turn && self.player02_name == fromPeer.description){
                        self.validateGuess(guess: request, playerId: fromPeer.description, player: 2)
                        self.isPlayer1Turn = true
                    }
                }
                
            }
        }
        catch let error {
            os_log("error didReceive \(error.localizedDescription)")
        }
    }
    
    func validateGuess(guess: String, playerId: String, player: Int){
        
        os_log("**** Validating guess \(guess)")
        
        let x = guess[guess.startIndex].wholeNumberValue ?? -1
        let y = guess[(guess.index(before: guess.endIndex))].wholeNumberValue ?? -1
        
        if x > self.treasureArray.numColumns { return }
        if y > self.treasureArray.numRows { return }
        
        if (self.numTreasures == 0){
            if (self.player01_score > self.player02_score){
                send(message: "Game Over. Player 01 wins")
            }
            else{
                send(message: "Game Over. Player 02 wins")
            }
        }
        else if (self.treasureArray.board[x][y] == 1){
            
            self.numTreasures -= 1
            self.treasureArray.board[x][y] = 0
            if (player == 1){
                self.player01_score += 1
            }
            else if (player == 2){
                self.player02_score += 1
            }
            print(self.treasureArray)
            send(message: "Found! Guess: " + guess + " Score is Player 1: " + String(player01_score) + " Player 2: " + String(player02_score) + ". Is it player 1's turn? " + String(self.isPlayer1Turn))

        }
        else{
            //send(message: "Player " + String(player) + " guessed " + guess + " and is Incorrect")
            send(message: "Try Again! Guess: " + guess + " Score is Player 1: " + String(player01_score) + " Player 2: " + String(player02_score) + ". Is it player 1's turn? " + String(self.isPlayer1Turn))
        }


    }
    
    /// Inherited from MCSessionDelegate.session(_:didStartReceivingResourceWithName:fromPeer:with:).
    /// Currently only logs.
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {
        os_log("didStartReceivingResourceWithName \(didStartReceivingResourceWithName) \(fromPeer) \(with)")
    }
    
    /// Inherited from MCSessionDelegate.session(_:didFinishReceivingResourceWithName:fromPeer:at:withError:).
    /// Currently only logs.
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {
        let at2 = at?.description ?? ""
        let withError2 = withError?.localizedDescription ?? ""
        os_log("didFinishReceivingResourceWithName \(didFinishReceivingResourceWithName) \(fromPeer) \(at2) \(withError2)")
    }
    
    /// Inherited from MCSessionDelegate.session(_:didReceive:withName:fromPeer:).
    /// Currently only logs.
    func session(_ session: MCSession, didReceive: InputStream, withName: String, fromPeer: MCPeerID) {
        os_log("didReceive:withName \(didReceive) \(withName) \(fromPeer)")
    }
    
    /// Inherited from MCSessionDelegate.session(_:peer:didChange:).
    /// Updates the connected state.
    func session(_ session: MCSession, peer: MCPeerID, didChange: MCSessionState) {
        switch didChange {
        case .notConnected:
            os_log("didChange notConnected \(peer)")
            removePeer(peer: peer)
            DispatchQueue.main.async {
                self.connected = false
            }
        case .connecting:
            os_log("didChange connecting \(peer)")
            DispatchQueue.main.async {
                self.connected = false
            }
        case .connected:
            os_log("didChange connected \(peer)")
            addPeer(peer: peer)
            DispatchQueue.main.async {
                self.connected = true
            }
        default:
            os_log("didChange \(peer)")
            DispatchQueue.main.async {
                self.connected = false
            }
        }
    }
    
    /// Inherited from MCSessionDelegate.session(_:didReceiveCertificate:fromPeer:certificateHandler:).
    /// Currently accepts all certificates.
    func session(_ session: MCSession, didReceiveCertificate: [Any]?, fromPeer: MCPeerID, certificateHandler: (Bool) -> Void) {
        let didReceiveCertificate2 = didReceiveCertificate?.description ?? ""
        os_log("didReceiveCertificate \(didReceiveCertificate2) \(fromPeer)")
        certificateHandler(true)
    }
    
    // MARK: - Data Transmission Method
    
    /// Sends a message to all registered peers.  Used by the client.
    /// - Parameter message: The message that is to be transmitted.
    func send(message: String) {
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: peers, with: .reliable)
    
            // TODO send only to specific player
            /*
            if (isPlayer1Turn){
                try session.send(data, toPeers: peers[0], with: .reliable)
            }
            else{
                try session.send(data, toPeers: peers[1], with: .reliable)
            }
             */
            
            os_log("send \(message)")
        }
        catch let error {
            os_log("send \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        os_log("deinit")
        nearbyServiceBrowser?.stopBrowsingForPeers()
    }
}
