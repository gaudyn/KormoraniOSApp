//
//  MeczeTableViewController.swift
//  Kormoran Beach Party ScoreAdmin
//
//  Created by Administrator on 03.07.2017.
//  Copyright © 2017 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
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
        
        let semaphore = DispatchSemaphore(value: 1)
        // USTAW TYTUŁ OKNA
        tournamentName.title = tournament?.name
        
        // WCZYTAJ MECZE Z SERWERA
        semaphore.wait()
        loadMatches()
        semaphore.signal()
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let semaphore = DispatchSemaphore(value: 1)
        self.matches.removeAll()
        // WCZYTAJ MECZE Z SERWERA
        semaphore.wait()
        loadMatches()
        semaphore.signal()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        // UPEWNIJ SIĘ, ŻE KOMÓRKA NALEŻY DO MECZETABLEVIEWCELL
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MeczeTableViewCell else{
            fatalError("The dequeued cell is not an instance of TurniejTableViewCell.")
        }
        
        // USTAW DANE W KOMÓRCE
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
        
        // USTAW AKCJĘ ROZPOCZĘCIA MECZU
        let progress = UITableViewRowAction(style: .normal, title: "Trwający") { action, index in
            
            let params = ["state" : "active", "username": KeychainWrapper.standard.string(forKey: "USER_LOGIN")!, "password": KeychainWrapper.standard.string(forKey: "USER_PASS")!, "tournament" : self.tournament!.id, "id" : self.matches[index.row].id] as [String:Any]
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            
            API().updateMatch(parameters: params, callback: {(error) in
                guard error == nil else{
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    return
                }
                DispatchQueue.main.async {
                    
                    self.matches.removeAll()
                    self.loadMatches()
                }
            })
            
            
            
        }
        progress.backgroundColor = .orange
        
        // USTAW AKCJĘ DODANIA MECZU DO OCZEKUJĄCYCH
        let ready = UITableViewRowAction(style: .normal, title: "Oczekujący") { action, index in
            
            let params = ["state" : "ready-to-play", "username": KeychainWrapper.standard.string(forKey: "USER_LOGIN")!, "password": KeychainWrapper.standard.string(forKey: "USER_PASS")!, "tournament" : self.tournament!.id, "id" : self.matches[index.row].id] as [String: Any]
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            
            API().updateMatch(parameters: params, callback: {(error) in
                guard error == nil else{
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    return
                }
                DispatchQueue.main.async {
                    
                    self.matches.removeAll()
                    self.loadMatches()
                }
                
            })
        }
        ready.backgroundColor = UIColor(red:0.30, green:0.85, blue:0.39, alpha:1.0)
        // JEŻELI MECZ JEST TRWAJĄCY DODAJ MOŻLIWOŚĆ DODANIA DO OCZEKUJĄCYCH. W INNYM WYPADKU DODAJ MOŻLIWOŚĆ ROZPOCZĘCIA
        if(matches[indexPath.row].state == "active"){
            return [ready]
        }else{
            return [progress]
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // JEŻELI MECZ JEST ZAKOŃCZONY WYŁĄCZ MOŻLIWOŚĆ EDYCJI
        if(matches[indexPath.row].state == "finished"){
            return false
        }else{
            return true
        }
    }

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
        let selectedMatch = matches[indexPath.row]
        
        // JEŻELI MECZ JEST ZAKOŃCZONY NIE POZWÓL NA EDYCJĘ PUNKTACJI
        if(selectedMatch.state == "finished" || selectedMatch.state == "ready_to_play"){
            let alertController = UIAlertController(title: "Mecz niedostępny", message: "Aby zmienić wynik meczu należy skontaktować się z administratorem", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        // PRZEŚLIJ DANE MECZU DO OKNA ZMIANY PUNKTÓW
        matchDetailViewController.match = selectedMatch
        matchDetailViewController.Pl1Name = selectedMatch.player1_id
        matchDetailViewController.Pl2Name = selectedMatch.player2_id
        matchDetailViewController.tournamentID = tournament!.id
        
    }
 
    @IBAction func unwindToMatchList(sender: UIStoryboardSegue) {
        matches.removeAll()
        loadMatches()
    }
    
    private func loadMatches(){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        API().loadMatches(tournamentID: tournament!.id, callback: {(matchs, error) in
            guard error == nil  && matchs != nil else{
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                return
            }
            self.matches = matchs!
            self.matches.sort(by: {$0.weight! < $1.weight!})
            DispatchQueue.main.async {
                self.tableView.reloadData()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
        
    }
   

}
