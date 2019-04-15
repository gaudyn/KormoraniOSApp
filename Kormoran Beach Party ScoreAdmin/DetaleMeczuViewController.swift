//
//  DetaleMeczuViewController.swift
//  Kormoran Admin System
//
//  Created by Gniewomir Gaudyn on 10.07.2017.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import UIKit
import os.log
import Alamofire
import SwiftKeychainWrapper
import Disk


class DetaleMeczuViewController: UIViewController, UITextFieldDelegate {
    
    
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var Player1Name: UILabel!
    @IBOutlet weak var Player1Score: UITextField!
    
    @IBOutlet weak var Player2Name: UILabel!
    @IBOutlet weak var Player2Score: UITextField!
    
    var Pl1Win = false
    var Pl2Win = false
    var match: Mecz?
    var Pl1Name: String?
    var Pl2Name: String?
    var tournamentID: String?
    var requestParameters: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFieldDelegates()
        
        setupPlayersNames()
        
        updateSaveButton()
        
        setupKeyboardToolbar()
    }
    
    func setupTextFieldDelegates(){
        Player1Score.delegate = self
        Player2Score.delegate = self
    }
    
    func setupPlayersNames(){
        Player1Name.text = Pl1Name!+":"
        Player2Name.text = Pl2Name!+":"
    }
    
    func setupKeyboardToolbar(){
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.doneClicked))
        toolbar.setItems([doneButton], animated: false)
        Player1Score.inputAccessoryView = toolbar
        Player2Score.inputAccessoryView = toolbar
    }
    
    @objc func doneClicked(){
        updateSaveButton()
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // ZABLOKUJ ZAPISANIE PO ROZPOCZĘCIU EDYCJI
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // SCHOWAJ KLAWIATURĘ
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButton()
    }
    
    // MARK: - Navigation
     
     @IBAction func Cancel(_ sender: UIBarButtonItem) {
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The DetaleMeczuViewController is not inside a navigation controller.")
        }
     }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // OPCJONALNE ALERTY KIEDY WCIŚNIĘTO PRZYCISK ZAPISANIA
        
        if let button = sender as? UIBarButtonItem, button === saveButton{
            updateParameters()
            
            var winner_id: String!
            var retrievedSettings: Settings!
            do{
                retrievedSettings = try Disk.retrieve("UserData/Settings.json", from: .applicationSupport, as: Settings.self)
            }catch{
                retrievedSettings = Settings(autoSetMatchWinner: true)
            }
            
            // JEŻELI MA WYŁONIĆ ZWYCIĘZCĘ
            if retrievedSettings.autoSetMatchWinner{
                
                if Int(Player1Score.text!)! > Int(Player2Score.text!)!{
                    winner_id = Pl1Name!
                } else if Int(Player1Score.text!)! < Int(Player2Score.text!)!{
                    winner_id = Pl2Name!
                }else{
                    // ŻADEN Z GRACZY NIE ZDOBYŁ WIĘCEJ PUNKTÓW
                    let promt = UIAlertController(title: "Remis",
                                                  message: "Nie można określić zwycięscy automatycznie.\nProszę wybrać ręcznie:",
                                                  preferredStyle: UIAlertController.Style.actionSheet)
                    
                    // GRACZ 1 WYGRYWA POMIMO BRAKU PRZEWAGI PUNKTÓW
                    let pl1_win = UIAlertAction(title: Pl1Name!, style: .default, handler:{
                        (alert) in
                        winner_id = String(describing: self.match!.player1_id)
                        self.requestParameters!["winner"] = winner_id!
                        self.updateScores()
                    })
                    
                    // GRACZ 2 WYGRYWA POMIMO BRAKU PRZEWAGI PUNKTÓW
                    let pl2_win = UIAlertAction(title: Pl2Name!, style: .default, handler:{
                        (alert) in
                        winner_id = String(describing: self.match!.player2_id)
                        self.requestParameters!["winner"] = winner_id!
                        self.updateScores()
                    })
                    
                    // ŻADEN Z GRACZY NIE WYGRYWA - GRA KOŃCZY SIĘ REMISEM
                    let tie = UIAlertAction(title: "Remis", style: .default, handler:{
                        (alert) in
                        winner_id = "tie"
                        self.requestParameters!["winner"] = winner_id!
                        self.updateScores()
                        
                    })
                    let cancel = UIAlertAction(title:"Anuluj", style: .cancel, handler: nil)
                    promt.addAction(pl1_win)
                    if (match?.ties)!{
                        promt.addAction(tie)
                    }
                    promt.addAction(pl2_win)
                    promt.addAction(cancel)
                    self.present(promt, animated: true, completion:nil)
                    return
                }
                
                self.requestParameters!["winner"] = winner_id!
                updateScores()
            }else{
                let promt = UIAlertController(title: "Wybierz zwycięzcę", message: nil, preferredStyle: .actionSheet)
                let team1 = UIAlertAction(title: self.Pl1Name!, style: .default, handler: {
                    (alert) in
                    winner_id = self.Pl1Name!
                    self.requestParameters!["winner"] = winner_id!
                    self.updateScores()
                    
                })
                let tie = UIAlertAction(title: "Remis", style: .default, handler: {
                    (alert) in
                    winner_id = "tie"
                    self.requestParameters!["winner"] = winner_id!
                    self.updateScores()
                })
                let team2 = UIAlertAction(title: self.Pl2Name, style: .default, handler: {
                    (alert) in
                    winner_id = self.Pl2Name!
                    self.requestParameters!["winner"] = winner_id!
                    self.updateScores()
                })
                let cancel = UIAlertAction(title: "Anuluj", style: .cancel, handler: nil)
                
                promt.addAction(team1)
                if match!.ties{
                    promt.addAction(tie)
                }
                promt.addAction(team2)
                promt.addAction(cancel)
                self.present(promt, animated: true, completion: nil)
            }
        }
    }
    private func updateParameters(){
        requestParameters = ["state" : "finished",
                             "points_team_1" : Int(self.Player1Score.text!)!,
                             "points_team_2" : Int(self.Player2Score.text!)!,
                             "username": KeychainWrapper.standard.string(forKey: "USER_LOGIN")!,
                             "password": KeychainWrapper.standard.string(forKey: "USER_PASS")!,
                             "tournament": self.tournamentID!,
                             "id": self.match!.id,
                             "winner": ""
        ]
    }
    
    @IBAction func Switched(_ sender: UISwitch) {
        updateSaveButton()
    }
    
    
    
    private func updateSaveButton(){
        if (Player1Score.text?.isEmpty)!{
            saveButton.isEnabled = false
        }else{
            if (Player2Score.text?.isEmpty)!{
                saveButton.isEnabled = false
            }else{
                saveButton.isEnabled = true
            }
        }
    }
    private func updateScores(){
        print(self.requestParameters!)
        API.updateMatch(parameters: self.requestParameters!, callback: {(error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            guard error == nil else{
                print("ERROR")
                print(error)
                
                return
            }
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        
        })
    }
}
