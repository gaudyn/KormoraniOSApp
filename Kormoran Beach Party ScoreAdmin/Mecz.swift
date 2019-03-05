//
//  Mecz.swift
//  Kormoran Beach Party ScoreAdmin
//
//  Created by Administrator on 03.07.2017.
//  Copyright © 2017 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import Foundation
import UIKit

class Mecz{
    
    var id: Int
    var player1_id: String
    var player2_id: String
    var state: String
    var color: UIColor!
    var score: String
    var weight: Int?
    var winner: String?
    var ties: Bool
    
    init?(id: Int, player1_id: String?, player2_id: String?, state: String, score: String, winner: String?, ties: Bool){
        //SPRAWDZENIE, CZY JEST ZWYCIĘSCA
        if(winner != nil){
            self.winner = winner
        }
        //ID TURNIEJU NIE MOŻE BYĆ PUSTE
        guard id != nil else{
            //fatalError("Could not set id")
            return nil
        }
        //STATUS TURNIEJU NIE MOŻE BYĆ PUSTY
        guard !state.isEmpty else{
            //fatalError("Could not set state")
            return nil
        }
        //PRZYPORZĄDKOWANIE KOLORU ORAZ WAGI (SORTOWANIE) DO MECZU
        if(state == "finished"){
            self.weight = 2
            self.color = UIColor(red:0.82, green:0.82, blue:0.82, alpha:0.3)
        }
        if(state == "ready-to-play" || state == "open"){
            self.weight = 1
            self.color = UIColor(red:0.52, green:0.92, blue:0.18, alpha:0.3)
        }
        if(state == "in-progress" || state == " in-progress"){
            self.weight = 0
            self.color = UIColor(red:1.00, green:0.85, blue:0.00, alpha:0.3)
        }
        //PRZYPORZĄDKOWANIE ARGUMENTÓW FUNKCJI DO WŁASNOŚCI OBIEKTÓW
        self.ties = ties
        self.id = id
        self.player2_id = player2_id ?? "???" //PRZYPORZĄDKOWUJE ??? JEŻELI ID = NIL
        self.player1_id = player1_id ?? "???"
        self.state = state
        self.score = score
        
    }
    func changeState(state: String){
        if(state == "finished"){
            self.weight = 2
            self.color = UIColor(red:0.82, green:0.82, blue:0.82, alpha:0.3)
        }
        if(state == "ready_to_play" || state == "open"){
            self.weight = 1
            self.color = UIColor(red:0.52, green:0.92, blue:0.18, alpha:0.3)
        }
        if(state == "in-progress" || state == " in-progress"){
            self.weight = 0
            self.color = UIColor(red:1.00, green:0.85, blue:0.00, alpha:0.3)
        }
        self.state = state;
    }
    
}
