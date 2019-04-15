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
        
        if let button = sender as? UIBarButtonItem, button === saveButton{
            updateParameters()
            
            if isAutoSetMatchWinner(){
                
                if canAutoSetWinner(){
                    setAutoWinner()
                } else{
                    let promt = UIAlertController(title: "Remis",
                                                  message: "Nie można określić zwycięscy automatycznie.\nProszę wybrać ręcznie:",
                                                  preferredStyle: UIAlertController.Style.actionSheet)
                    
                    promt.addAction(getWinnerAlert(winner: Pl1Name!))
                    if (match?.ties)!{
                        promt.addAction(getTieAlert())
                    }
                    promt.addAction(getWinnerAlert(winner: Pl2Name!))
                    promt.addAction(getCancelAlert())
                    self.present(promt, animated: true, completion:nil)
                    return
                }
                
            }else{
                let promt = UIAlertController(title: "Wybierz zwycięzcę", message: nil, preferredStyle: .actionSheet)
                
                promt.addAction(getWinnerAlert(winner: Pl1Name!))
                if match!.ties{
                    promt.addAction(getTieAlert())
                }
                promt.addAction(getWinnerAlert(winner: Pl2Name!))
                promt.addAction(getCancelAlert())
                
                self.present(promt, animated: true, completion: nil)
            }
        }
    }
    
    func isAutoSetMatchWinner() -> Bool{
        var retrievedSettings: Settings!
        do{
            retrievedSettings = try Disk.retrieve("UserData/Settings.json", from: .applicationSupport, as: Settings.self)
        }catch{
            retrievedSettings = Settings(autoSetMatchWinner: true)
        }
        return retrievedSettings.autoSetMatchWinner
    }
    
    func canAutoSetWinner() -> Bool{
        if Int(Player1Score.text!)! > Int(Player2Score.text!)!{
            return true
        } else if Int(Player1Score.text!)! < Int(Player2Score.text!)!{
            return true
        }
        return false
    }
    
    func setAutoWinner(){
        var winnerId: String
        if Int(Player1Score.text!)! > Int(Player2Score.text!)!{
            winnerId = Pl1Name!
        } else{
            winnerId = Pl2Name!
        }
        
        requestParameters!["winner"] = winnerId
        updateScores()
    }
    
    func getWinnerAlert(winner: String) -> UIAlertAction{
        let alert = UIAlertAction(title: winner, style: .default, handler: {
            (alert) in
            self.requestParameters!["winner"] = winner
            self.updateScores()
        })
        return alert
    }
    
    func getTieAlert() -> UIAlertAction{
        let alert = UIAlertAction(title: "Remis", style: .default, handler: {
            (alert) in
            self.requestParameters!["winner"] = "tie"
            self.updateScores()
        })
        return alert
    }
    
    func getCancelAlert() -> UIAlertAction{
        let alert = UIAlertAction(title: "Anuluj", style: .cancel, handler: nil)
        return alert
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
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
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
