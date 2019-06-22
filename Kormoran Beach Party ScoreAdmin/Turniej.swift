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
        
        
        if(game == "handball"){
            self.photo = #imageLiteral(resourceName: "Handball")
        }
        if(game == "basketball"){
            self.photo = #imageLiteral(resourceName: "Basketball")
        }
        if(game == "volleyball"){
            self.photo = #imageLiteral(resourceName: "Volleyball")
        }
        if(game == "soccer"){
            self.photo = #imageLiteral(resourceName: "Football")
        }
        if(game == "tug_of_war"){
            self.photo = #imageLiteral(resourceName: "Tug")
        }
        
        if(state == NSLocalizedString("stateReady", comment: "Tournament is ready to play")){
            self.state_photo = UIImage(named: "Circle-Green")
            weight = 1
        }
        if(state == NSLocalizedString("stateFinished", comment: "Tournament has been finished")){
            self.state_photo = UIImage(named: "Circle-Black")
            weight = 0
        }
        if(state == NSLocalizedString("stateProgress", comment: "Tournament is in progress")){
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
