//
//  TurniejeTableViewController.swift
//  Kormoran Beach Party ScoreAdmin
//
//  Created by Administrator on 02.07.2017.
//  Copyright © 2017 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import UIKit
import Foundation
import os.log
import Alamofire
import SwiftKeychainWrapper

class TurniejeTableViewController: UITableViewController, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.filteredTournaments =  self.tournaments.filter { (turniej: Turniej) -> Bool in
            if turniej.name.lowercased().contains(self.searchController.searchBar.text!.lowercased()) {
                return true
            }else{
                return false
            }
        }
        
        self.tableView.reloadData()
    }
    

    var tournaments = [Turniej]()
    var filteredTournaments = [Turniej]()
    var refresher: UIRefreshControl!
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true;
        
        
        // DODAJ MOŻLIWOŚĆ ODŚWIEŻANIA TABELI
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: NSLocalizedString("refresherString", comment: "A string for a refresher")) 
        refresher.addTarget(self, action: #selector(TurniejeTableViewController.refresh), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refresher;
        
        
        
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Wyszukaj turnieje"
        
        definesPresentationContext = true
        
        
        // SPRAWDŹ POŁĄCZENIE Z INTERNETEM
        if Reachability.isConnectedToNetwork() == true{
            loadChallongeTournaments();
        }else{
            //WYŚWIETL ALERT O BRAKU INTERNETU
            let alertController = UIAlertController(title: NSLocalizedString("noInternet", comment: "A string for no internet alert"), message: NSLocalizedString("noInternetMessage", comment: "Message for no internet alert"), preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: NSLocalizedString("okString", comment: "A string for ok action"), style: UIAlertAction.Style.cancel)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        
        
    }
    
    @objc func refresh(){
        //SPRAWDŹ POŁĄCZENIE Z INTERNETEM
        if Reachability.isConnectedToNetwork() == true{
            let semaphore = DispatchSemaphore(value: 1)
            //CZEKAJ NA WCZYTANIE DANYCH
            semaphore.wait()
            tournaments.removeAll()
            loadChallongeTournaments()
            semaphore.signal()
            // PRZEŁADUJ DANE W TABELI
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
            
            // ZAKOŃCZ ODŚWIEŻANIE
            refresher.endRefreshing()
        }else{
            // WYŚWIETL ALERT O BRAKU INTERNETU
            let alertController = UIAlertController(title: NSLocalizedString("noInternet", comment: "A string for no internet alert"), message: NSLocalizedString("noInternetMessage", comment: "Message for no internet alert"), preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: NSLocalizedString("okString", comment: "A string for ok action"), style: UIAlertAction.Style.cancel)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion:({
                self.refresher.endRefreshing()
                return
            }))
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if tournaments.count > 0 {
            tableView.separatorStyle = .singleLine
            tableView.tableFooterView = .none
            return 1
        }else{
            
            let bgLabel = UILabel();
            bgLabel.text = NSLocalizedString("tableViewEmpty", comment: "Empty table view")
            bgLabel.textColor = .gray
            bgLabel.textAlignment = .center
            bgLabel.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.bounds.size.width, height: tableView.bounds.size.height/2))
            tableView.tableFooterView = bgLabel
            tableView.separatorStyle = .none
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isFiltering(){
            return tournaments.count
        }else{
            return filteredTournaments.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "TurniejTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TurniejTableViewCell else{
            fatalError("Cell is not an instance of TurniejeTableViewCell")
        }
        let tour: Turniej
        if !isFiltering(){
            tour = self.tournaments[indexPath.row]
            
        }else{
            tour = self.filteredTournaments[indexPath.row]
        }
        cell.name.text = tour.name
        cell.photo.image = tour.photo
        cell.state.text = tour.state
        cell.state_photo.image = tour.state_photo
        return cell
        
    }

    private func searchBarIsEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func isFiltering() -> Bool{
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
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
        
        guard let selectedMatchCell = sender as? TurniejTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedMatchCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        // JEŻELI TURNIEJ OCZEKUJE NA ROZPOCZĘCIE I UŻYTKOWNIK NIE JEST ZALOGOWANY PRZERWIJ PRZEJŚCIE
        if(tournaments[indexPath.row].state == "Oczekujący" && KeychainWrapper.standard.string(forKey: "USER_PASS") == nil){
            return false
        }
        return true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        guard let matchDetailViewController = segue.destination as? MeczeTableViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        guard let selectedMatchCell = sender as? TurniejTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedMatchCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        // JEŻELI TURNIEJ NIE JEST ROZPOCZĘTY ZAPYTAJ, CZY NALEŻY ROZPOCZĄĆ
        if(tournaments[indexPath.row].state == "Oczekujący" && !(KeychainWrapper.standard.string(forKey: "USER_LOGIN")?.isEmpty)!){
            let alertController = UIAlertController(title: NSLocalizedString("tournamentStartTitle", comment: "tournament alert start title"), message: NSLocalizedString("tournamentStartMessage", comment: "message for tournament start alert"), preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancelAction", comment: "Cancelling action of an alert"), style: UIAlertAction.Style.cancel)
            let okAction = UIAlertAction(title: NSLocalizedString("okString", comment: "Ok string alert action"), style: UIAlertAction.Style.default, handler:{
                (alert) in
                let semaphore = DispatchSemaphore(value: 1)
                
                // TODO: DO POPRAWKI NA SERWER KORMORANSYSTEM
                
                Alamofire.request("https://gniewko717:04IgRjZLdPLL3RoVza7TWz3Ly3BukWnWtstBoGlf@api.challonge.com/v1/tournaments/\(self.tournaments[indexPath.row].id)/start.json", method: .post).response{ response in
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Error: \(response.error)")
                    
                    if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                        print("Data: \(utf8Text)")
                        
                    }
                }
                // PRZEŁADUJ TURNIEJE
                self.tournaments.removeAll()
                semaphore.wait()
                self.self.loadChallongeTournaments()
                semaphore.signal()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
            
            
            alertController.addAction(cancelAction)
            //alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
            
        }
        
        let selectedTournament = tournaments[indexPath.row]
        matchDetailViewController.tournament = selectedTournament
    }
 
    
    //MARK: Private Methods
    private func loadChallongeTournaments(){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        API().loadTournaments(callback: {(tours, error) in
            guard error == nil && tours != nil else{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            self.tournaments = tours!
            DispatchQueue.main.async {
                self.tableView.reloadData()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            })
    }
}
