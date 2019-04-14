//
//  Turniej.swift
//  Kormoran Admin System
//
//  Created by Gniewomir Gaudyn on 02.07.2017.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import Foundation
import UIKit
class Turniej{
    var name: String!
    var photo: UIImage?
    var game: String
    var state: String
    var state_photo: UIImage?
    var id: String
    var weight: Int?
    var ties: Bool
    
    init?(name: String!, game: String?, state: String?, id: String?, ties: Bool?){
        //NAZWA TURNIEJU NIE MOŻE BYĆ PUSTA
        guard name != nil && !name!.isEmpty else {
            //fatalError("Nie można stworzyć turnieju - brak nazwy")
            return nil
        }
        //STATUS TURNIEJU NIE MOŻE BYĆ PUSTY
        guard !(state?.isEmpty)! else {
            //fatalError("Nie można stworzyć turnieju - brak statusu")
            return nil
        }
        //ID TURNIEJU NIE MOŻE BYĆ PUSTE
        guard !(id?.isEmpty)! else{
            //fatalError("Nie można stworzyć turnieju - brak id")
            return nil
        }
        //GRA TURNIEJU NIE MOŻE BYĆ PUSTA
        guard !(game?.isEmpty)! else {
            //fatalError("Nie można stworzyć turnieju - brak gry")
            return nil
        }
        //USTAWIANIE MINIATURKI GRY
        if(game == "handball"){
            self.photo = UIImage(named: "Handball")
        }
        if(game == "basketball"){
            self.photo = UIImage(named: "Basketball")
        }
        if(game == "volleyball"){
            self.photo = UIImage(named: "Volleyball")
        }
        if(game == "soccer"){
            self.photo = #imageLiteral(resourceName: "Football")
        }
        //USTAWIANIE KOLORU TURNIEJU I JEGO WAGI (POTRZEBNE DO SORTOWANIA)
        if(state == "Oczekujący"){
            self.state_photo = UIImage(named: "Circle-Green")
            weight = 1
        }
        if(state == "Zakończony"){
            self.state_photo = UIImage(named: "Circle-Black")
            weight = 0
        }
        if(state == "Trwający"){
            self.state_photo = UIImage(named: "Circle-Yellow")
            weight = 2
        }
        
        //PRZYPORZĄDKOWANIE ARGUMENTÓW FUNKCJI DO WŁASNOŚCI OBIEKTUS
        self.game = game!
        self.ties = ties!
        self.name = name!
        self.state = state!
        self.id = id!
    }
    
}
