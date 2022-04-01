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
    
    var numColumns = 5
    var numRows = 5
    var numTreasures = 5
    //var treasureArray : [[Int]]
    
    var body: some View {
        VStack {
            if !advertising {
                Button("Start") {
                    networkSupport.nearbyServiceAdvertiser?.startAdvertisingPeer()
                    advertising.toggle()
                }
            }
            else {
                Text(networkSupport.incomingMessage)
                    .padding()
                
                if networkSupport.connected {
                    Button("Reply") {
                        //networkSupport.send(message: "Thank you for: " + networkSupport.incomingMessage)
                        //let reply = "Here is the board: "
                        let flattened = initializeArray().flatMap { $0 }
                        let stringArray = flattened.map { String($0) }
                        //reply += stringArray
                        networkSupport.send(message: "Here is the board: " + stringArray.joined(separator: ", "))
                    }
                    .padding()
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
    
    func initializeArray() -> [[Int]]{
        
        // initialize array to be all 0's
        var treasureArray = Array(repeating: Array(repeating: 0, count: numColumns), count: numRows)
        
        // place n number of treasures
        for _ in 0...numTreasures {
            let randX = Int.random(in: 1..<numRows)
            let randY = Int.random(in: 1..<numColumns)
            treasureArray[randX][randY] = 1
        }
        
        return treasureArray
        
    }
}
