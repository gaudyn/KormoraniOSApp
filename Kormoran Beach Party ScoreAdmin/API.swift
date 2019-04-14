//
//  API.swift
//  Kormoran Beach Party
//
//  Created by Gniewomir Gaudyn on 02/03/2019.
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
    
    class func loadTournaments(callback: @escaping (_ turnieje: [Turniej]?, _ error: Error?) -> Void){
        
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
                            if(tournament["state"] as? String == "finished"){
                                status = "Zakończony"
                            }
                            let turniej = Turniej(name: tournament["rep_name"] as? String, game: tournament["game"] as? String, state: status, id: tournament["name"] as? String, ties: false)
                            if turniej != nil{
                                tournaments.append(turniej!)
                            }
                        }
                        callback(tournaments, nil)
                    }
                }
            }
            callback(nil, APIError(kind: .forbiddenAccess))
            }
        }
        task.resume()
    }
    
    class func loadMatches(tournamentID: String!, callback: @escaping (_ mecze: [Mecz]?, _ error: Error?) -> Void){
        
        var matchURL = url+subUrls["matches"]!+"?tournament="+tournamentID
        if let username = KeychainWrapper.standard.string(forKey: "USER_LOGIN"), let password =  KeychainWrapper.standard.string(forKey: "USER_PASS"){
            matchURL+="&username=\(username)&password=\(password)"
        }
        var request = URLRequest(url: URL(string: matchURL)!)
        request.httpMethod = "GET"
        
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.global(qos: .utility).async {
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200{
                    callback(nil, APIError(kind: .invalidStatusCode))
                }
                if error != nil{
                    callback(nil, error)
                }
                    
                else{
                    if let content = data{
                        let json = try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]
                        if let jsonMatches = json??["matches"] as? [[String: Any]]{
                            var matches = [Mecz]()
                            for match in jsonMatches{
                                
                                let id = match["match_id"] as! Int
                                let state = match["state"] as! String
                                
                                let team_1 = match["team_1"] as? String
                                let team_2 = match["team_2"] as? String
                                
                                let winner = match["winner"] as? String
                                
                                let team_1_score = match["points_team_1"] as? Int ?? 0
                                let team_2_score = match["points_team_2"] as? Int ?? 0
                                
                                let scores = String(describing: team_1_score)+"-"+String(describing: team_2_score)
                                let mecz = Mecz(id: id, player1_id: team_1, player2_id: team_2, state: state, score: scores, winner: winner, ties: false)
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
    class func updateMatch(parameters: [String:Any]!, callback: @escaping (_ error: Error?) -> Void){
        
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
    class func login(parameters: [String:String]!, callback: @escaping (_ error: Error?) -> Void){
        
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
