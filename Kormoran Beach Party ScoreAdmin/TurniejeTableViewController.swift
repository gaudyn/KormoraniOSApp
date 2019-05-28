//
//  TurniejeTableViewController.swift
//  Kormoran Admin System
//
//  Created by Gniewomir Gaudyn on 02.07.2017.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import UIKit
import Foundation
import os.log
import Alamofire
import SwiftKeychainWrapper

class TurniejeTableViewController: UITableViewController, UISearchResultsUpdating {

    var tournaments = [Turniej]()
    var filteredTournaments = [Turniej]()
    var refresher: UIRefreshControl!
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true;
        
        setupRefresher()
        
        setupSearchController()
        
        definesPresentationContext = true
        
        if isInternetConnection(){
            loadTournaments();
        }else{
            noInternetConnectionAlert()
        }
    }
    
    func setupRefresher(){
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: NSLocalizedString("refresherString", comment: "A string for a refresher"))
        refresher.addTarget(self, action: #selector(TurniejeTableViewController.refreshTableContents), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refresher;
    }
    
    func setupSearchController(){
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Wyszukaj turnieje"
        
    }
    
    internal func updateSearchResults(for searchController: UISearchController) {
        self.filteredTournaments =  self.tournaments.filter { (turniej: Turniej) -> Bool in
            if turniej.name.lowercased().contains(self.searchController.searchBar.text!.lowercased()) {
                return true
            }else{
                return false
            }
        }
        
        self.tableView.reloadData()
    }
    
    @objc func refreshTableContents(){
        if isInternetConnection(){
            loadTournaments()
        }else{
            noInternetConnectionAlert()
        }
        refresher.endRefreshing()
    }
    
    func isInternetConnection() -> Bool{
        return Reachability.isConnectedToNetwork()
    }
    
    func noInternetConnectionAlert(){
        let alertController = UIAlertController(title: NSLocalizedString("noInternet", comment: "A string for no internet alert"), message: NSLocalizedString("noInternetMessage", comment: "Message for no internet alert"), preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: NSLocalizedString("okString", comment: "A string for ok action"), style: UIAlertAction.Style.cancel)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        if isTableFiltered(){
            return filteredTournaments.count
        }else{
            return tournaments.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "TurniejTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TurniejTableViewCell else{
            fatalError("Cell is not an instance of TurniejeTableViewCell")
        }
        let cellTournament: Turniej
        if !isTableFiltered(){
            cellTournament = self.tournaments[indexPath.row]
            
        }else{
            cellTournament = self.filteredTournaments[indexPath.row]
        }
        cell.name.text = cellTournament.name
        cell.photo.image = cellTournament.photo
        cell.state.text = cellTournament.state
        cell.state_photo.image = cellTournament.state_photo
        return cell
        
    }

    private func searchBarIsEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func isTableFiltered() -> Bool{
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
 
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        guard let selectedMatchCell = sender as? TurniejTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedMatchCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        if(tournaments[indexPath.row].state == "Oczekujący" && KeychainWrapper.standard.string(forKey: "USER_PASS") == nil){
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        
        let selectedTournament = tournaments[indexPath.row]
        matchDetailViewController.tournament = selectedTournament
    }
 
    
    //MARK: Private Methods
    private func loadTournaments(){
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        API.loadTournaments(callback: {(tours, error) in
            guard error == nil && tours != nil else{
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                print(error)
                return
            }
            
            self.tournaments.removeAll()
            self.tournaments = tours!
            self.tournaments.sort(by: {$0.weight! > $1.weight!})
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            })
    }
}
