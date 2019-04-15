//
//  MeczeTableViewController.swift
//  Kormoran Admin System
//
//  Created by Gniewomir Gaudyn on 03.07.2017.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import Alamofire
import os.log

class MeczeTableViewController: UITableViewController {

    @IBOutlet weak var tournamentName: UINavigationItem!
    var tournament: Turniej?
    var matches = [Mecz]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle()
        
        loadMatches()
    }
    
    func setTitle(){
        tournamentName.title = tournament?.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadMatches()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "MeczeTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MeczeTableViewCell else{
            fatalError("The dequeued cell is not an instance of TurniejTableViewCell.")
        }
        
        let match = matches[indexPath.row]
        cell.player1Name.text = match.player1_id
        cell.player2Name.text = match.player2_id
        if(matches[indexPath.row].winner != nil){
            if(matches[indexPath.row].winner == matches[indexPath.row].player1_id){
                cell.player1Name.font = UIFont.boldSystemFont(ofSize: 17.0)
            }else{
                cell.player2Name.font = UIFont.boldSystemFont(ofSize: 17.0)
            }
        }
        
        cell.Score.text = match.score
        cell.backgroundColor = match.color
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let changeMatchToInProgress = UITableViewRowAction(style: .normal, title: "Trwający") { action, index in
            
            let params = ["state" : "active", "username": KeychainWrapper.standard.string(forKey: "USER_LOGIN")!, "password": KeychainWrapper.standard.string(forKey: "USER_PASS")!, "tournament" : self.tournament!.id, "id" : self.matches[index.row].id] as [String:Any]
            
            self.updateMatch(requestParameters: params)
        }
        changeMatchToInProgress.backgroundColor = .orange
        
        let changeMatchToReady = UITableViewRowAction(style: .normal, title: "Oczekujący") { action, index in
            
            let params = ["state" : "ready-to-play", "username": KeychainWrapper.standard.string(forKey: "USER_LOGIN")!, "password": KeychainWrapper.standard.string(forKey: "USER_PASS")!, "tournament" : self.tournament!.id, "id" : self.matches[index.row].id] as [String: Any]
            
            self.updateMatch(requestParameters: params)
            
        }
        changeMatchToReady.backgroundColor = UIColor(red:0.30, green:0.85, blue:0.39, alpha:1.0)
        
        if(matches[indexPath.row].state == "active"){
            return [changeMatchToReady]
        }else{
            return [changeMatchToInProgress]
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        if(matches[indexPath.row].state == "finished"){
            return false
        }else{
            return true
        }
    }

    
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // JEŻELI UŻYTKOWANIK JEST ZALOGOWANY POZWÓL MU EDYTOWAĆ PUNKTY MECZU
        
        if identifier == "showMatchDetails"{
            if KeychainWrapper.standard.string(forKey: "USER_LOGIN") != nil{
                return true
            }else{
                return false
            }
        }else{
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        
        guard let matchDetailViewController = segue.destination as? DetaleMeczuViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        guard let selectedMealCell = sender as? MeczeTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        guard indexPath.row < matches.count else{
            return
        }
        let selectedMatch = matches[indexPath.row]
        
        // JEŻELI MECZ JEST ZAKOŃCZONY NIE POZWÓL NA EDYCJĘ PUNKTACJI
        if(selectedMatch.state == "finished" || selectedMatch.state == "ready_to_play"){
            let alertController = UIAlertController(title: "Mecz niedostępny", message: "Aby zmienić wynik meczu należy skontaktować się z administratorem", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        matchDetailViewController.match = selectedMatch
        matchDetailViewController.Pl1Name = selectedMatch.player1_id
        matchDetailViewController.Pl2Name = selectedMatch.player2_id
        matchDetailViewController.tournamentID = tournament!.id
        
    }
 
    @IBAction func unwindToMatchList(sender: UIStoryboardSegue) {
        loadMatches()
    }
    
    private func loadMatches(){
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        API.loadMatches(tournamentID: tournament!.id, callback: {(matchs, error) in
            guard error == nil  && matchs != nil else{
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                return
            }
            self.matches.removeAll()
            self.matches = matchs!
            self.matches.sort(by: {$0.weight! < $1.weight!})
            
            DispatchQueue.main.async {
                
                self.tableView.reloadData()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
    }
    
    private func updateMatch(requestParameters: [String:Any]){
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        
        API.updateMatch(parameters: requestParameters, callback: {(error) in
            guard error == nil else{
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                return
            }
            self.loadMatches()
        })
    }
   

}
