//
//  API.swift
//  Kormoran Beach Party
//
//  Created by Administrator on 02/03/2019.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

struct APIError: Error{
    enum ErrorKind{
        case missingParameters
        case forbiddenAccess
        case invalidStatusCode
        case invalidLoginOrPass
    }
    let kind: ErrorKind
}

class API {
    let url = "https://code.legnica.pl/kormoran/api"
    let subUrls = [
        "tournaments" : "/tournaments.php",
        "matches" : "/matches.php",
        "administrate" : "/administrate.php"
    ]
    
    // TODO
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
                    callback(nil, APIError(kind: .invalidStatusCode))
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
            callback(nil, APIError(kind: .forbiddenAccess))
            }
        }
        task.resume()
    }
    
    //ZWRACA TABLICĘ MECZY Z API
    func loadMatches(tournamentID: String!, callback: @escaping (_ mecze: [Mecz]?, _ error: Error?) -> Void){
        
        // USTAW URL SERWERA
        var matchURL = url+subUrls["matches"]!+"?tournament="+tournamentID
        if let username = KeychainWrapper.standard.string(forKey: "USER_LOGIN"), let password =  KeychainWrapper.standard.string(forKey: "USER_PASS"){
            matchURL+="&username=\(username)&password=\(password)"
        }
        var request = URLRequest(url: URL(string: matchURL)!)
        // USTAW METODĘ REQESTU
        request.httpMethod = "GET"
        
        
        // WYŚLIJ REQUEST
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.global(qos: .utility).async {
                //print(data)
                //print(response)
                //print(error)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200{
                    callback(nil, APIError(kind: .invalidStatusCode))
                }
                if error != nil{
                    callback(nil, error)
                }
                    
                else{
                    // ODEBRANO DANE
                    if let content = data{
                        // SERIALIZACJA JSONA
                        let json = try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]
                        if let jsonMatches = json??["matches"] as? [[String: Any]]{
                            var matches = [Mecz]()
                            // DLA KAŻDEGO MECZU STWÓRZ NOWY OBIEKT MECZU
                            for match in jsonMatches{
                                
                                let id = match["match_id"] as! Int
                                let state = match["state"] as! String
                                
                                let team_1 = match["team_1"] as? String
                                let team_2 = match["team_2"] as? String
                                
                                let winner = match["winner"] as? String
                                
                                let team_1_score = match["points_team_1"] as? Int ?? 0
                                let team_2_score = match["points_team_2"] as? Int ?? 0
                                
                                let scores = String(describing: team_1_score)+"-"+String(describing: team_2_score)
                                // STWÓRZ OBIEKT MECZU
                                let mecz = Mecz(id: id, player1_id: team_1, player2_id: team_2, state: state, score: scores, winner: winner, ties: false)
                                // DODAJ DO TABLICY I PRZEŁADUJ DANE
                                if mecz != nil{
                                    matches.append(mecz!)
                                }
                            }
                            callback(matches, nil)
                        }
                    }
                }
                callback(nil, APIError(kind: .forbiddenAccess))
            }
        }
        task.resume()
        
    }
    //AKTUALIZUJE MECZ PODANYMI PARAMETRAMI
    func updateMatch(parameters: [String:Any]!, callback: @escaping (_ error: Error?) -> Void){
        
        guard parameters["tournament"] != nil, parameters["id"] != nil else{
            print("Couldn't find tournamentId or matchId")
            callback(APIError(kind: .missingParameters))
            return
        }
        
        let matchUrl = url+subUrls["matches"]!
        
        var request = URLRequest(url:URL(string: matchUrl)!)
        
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        }catch{
            print(error.localizedDescription)
        }
        
        
        
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request){(data, response, error) in
            DispatchQueue.global(qos: .utility).async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200{
                    callback(APIError(kind: .invalidStatusCode))
                }
                guard error == nil else{
                    callback(error)
                    return
                }
                callback(nil)
            }
        }
        task.resume()
        
        
    }
    //SPRAWDZA CZY PODANY LOGIN I HASLO SA POPRAWNE
    func login(parameters: [String:String]!, callback: @escaping (_ error: Error?) -> Void){
        
        guard parameters["username"] != nil, parameters["password"] != nil else{
            print("No username or password provided")
            callback(APIError(kind: .missingParameters))
            return
        }
        
        let requestUrl = url+subUrls["administrate"]!
        
        var request = URLRequest(url: URL(string: requestUrl)!)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        }catch{
            print(error.localizedDescription)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request){(data, response, error) in
            DispatchQueue.global(qos: .utility).async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200{
                    callback(APIError(kind: .invalidStatusCode))
                }
                guard error == nil else{
                    callback(error)
                    return
                }
                if let content = data, let utf8Text = String(data: content, encoding: .utf8){
                    if(utf8Text.contains("\"error\":true")){
                        callback(APIError(kind: .invalidLoginOrPass))
                    }
                }
                callback(nil)
            }
        }
        task.resume()
        
    }
    
}
