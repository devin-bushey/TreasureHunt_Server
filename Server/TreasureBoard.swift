//
//  TreasureBoard.swift
//  Server
//
//  Created by ICS 224 on 2022-04-08.
//

import Foundation
import SwiftUI
import os

/// This structure is used at setup the board
/// It is initialized with number of columns, rows, and treasures are placed randomly
struct TreasureBoard: Identifiable, Codable {
    
    var id = UUID()
    var board: [[Int]]
    var numColumns: Int
    var numRows: Int
    var numTreasures : Int
    
    init(numColumns: Int, numRows: Int, numTreasures: Int){
        self.numColumns = numColumns
        self.numRows = numRows
        self.numTreasures = numTreasures
        self.board = Array(repeating: Array(repeating: 0, count: self.numColumns), count: self.numRows)
        
        /// randmoly place treasures (as 1's) on the board
        for _ in 1...self.numTreasures {
            let randX = Int.random(in: 1..<self.numRows)
            let randY = Int.random(in: 1..<self.numColumns)
            self.board[randX][randY] = 1
        }
        
        print(board)
    }
}

