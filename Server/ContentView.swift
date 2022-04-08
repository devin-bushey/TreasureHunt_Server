//
//  ContentView.swift
//  Server
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

struct ContentView: View {
    @State var advertising = false
    @StateObject var networkSupport = NetworkSupport(browse: false)
    
    var body: some View {
        VStack {
            if !advertising {
                Button("Start") {
                    networkSupport.nearbyServiceAdvertiser?.startAdvertisingPeer()
                    advertising.toggle()
                }
            }
            else {
                VStack{
                    Text("Test")
                    Text("Is Player 1's turn? " + String(networkSupport.isPlayer1Turn))
                    Text("Network Peer Name: " + networkSupport.peerName)
                    Text("Incoming Message: " + networkSupport.incomingMessage)
                    Text("Number of peers connected: " + String(networkSupport.peers.count))
                }
                Button("Stop") {
                    networkSupport.nearbyServiceAdvertiser?.stopAdvertisingPeer()
                    advertising.toggle()
                }
                .padding()
            }
        }
        .padding()
    }

    
}


