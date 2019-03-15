//
//  API.swift
//  Kormoran Beach Party
//
//  Created by Administrator on 02/03/2019.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

class API {
    let url = "https://code.legnica.pl/kormoran/api"
    let subUrls = [
        "tournaments" : "/tournaments.php",
        "matches" : "/matches.php"
    ]
    
    // SPRAWDZA POŁĄCZENIE Z API, true: połączono, false: brak połączenia
    func checkConnection() -> Bool{
        let tournamentsURL = url+subUrls["tournaments"]!
        var httpRequest = URLRequest(url: URL(string: tournamentsURL)!)
        
        httpRequest.httpMethod = "GET"
        var Success = true
        let task = URLSession.shared.dataTask(with: httpRequest){ (data, response, error) in DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode != 200{
                        Success = false
                        return
                    }
                }
                if error != nil{
                    Success = false
                    return
                }
            }
        }
        task.resume()
        return Success
    }
    
    // ZWRACA TABLICĘ TURNIEJÓW Z API
    func loadTournaments(callback: @escaping (_ turnieje: [Turniej]?, _ error: Error?) -> Void){
        var tournamentsURL = url+subUrls["tournaments"]!
        if let username = KeychainWrapper.standard.string(forKey: "USER_LOGIN"), let password =  KeychainWrapper.standard.string(forKey: "USER_PASS"){
            tournamentsURL+="?username=\(username)&password=\(password)"
        }
        var httpRequest = URLRequest(url: URL(string: tournamentsURL)!)
        
        httpRequest.httpMethod = "GET"
    
        let task = URLSession.shared.dataTask(with: httpRequest){ (data, response, error) in DispatchQueue.global(qos: .utility).async {
            if let httpResponse = response as? HTTPURLResponse{
                if httpResponse.statusCode != 200{
                    callback(nil, error)
                }
            }
            if error != nil{
                callback(nil, error)
            }
            else{
                if let content = data{
                    
                    // SERIALIZACJA JSONA
                    let json = try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]
                    
                    if let jsonTournaments = json??["tournaments"] as? [[String: Any]]{
                        var tournaments = [Turniej]()
                        for tournament in jsonTournaments{
                            var status = "undefined"
                            // USTAWIANIE STATUSU TURNIEJU
                            if(tournament["state"] as? String == "ready-to-play"){
                                status = "Oczekujący"
                            }
                            if(tournament["state"] as? String == "active"){
                                status = "Trwający"
                            }
                            if(tournament["state"] as? String == "complete"){
                                status = "Zakończony"
                            }
                            // TWORZENIE NOWEGO TURNIEJU
                            let turniej = Turniej(name: tournament["rep_name"] as? String, game: tournament["game"] as? String, state: status, id: tournament["name"] as? String, ties: false)
                            // DODAWANIE TURNIEJU DO TABLICY
                            if turniej != nil{
                                tournaments.append(turniej!)
                            }
                        }
                        //tournaments.sort(by: {$0.weight! > $1.weight!})
                        callback(tournaments, nil)
                    }
                }
            }
            callback(nil, error)
            }
        }
        task.resume()
    }
    
}
