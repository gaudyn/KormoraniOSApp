//
//  Logins.swift
//  Kormoran Admin System
//
//  Created by Gniewomir Gaudyn on 18.07.2017.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import Foundation

class validLogin{
    
    let validLogins = ["gniewko717", "mateuszmaterek"]
    
    func checkIfValid(user: String) -> Bool{
        if(validLogins.contains(user)){
            return true
        }else{
            return false
        }
    }
}
