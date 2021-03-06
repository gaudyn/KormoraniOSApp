//
//  SettingsView.swift
//  Kormoran Beach Party
//
//  Created by Gniewomir Gaudyn on 06.05.2018.
//  Copyright © 2018 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Foundation
import Disk
import CryptoSwift


struct Settings: Codable{
    var autoSetMatchWinner: Bool
}

class SettingsView: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var PictureTap: UITapGestureRecognizer!
    @IBOutlet var NameDataTap: UITapGestureRecognizer!
    @IBOutlet weak var UserData: UILabel!
    @IBOutlet weak var UserPicture: UIImageView!
    @IBOutlet weak var UserTeams: UITableViewCell!
    
    @IBOutlet weak var autoSetWinnerSwitch: UISwitch!
    
    var loginAlert: UIAlertController!;
    
    var UserLogged: Bool!;
    
    //Social medias
    @IBOutlet var FacebookTap: UITapGestureRecognizer!
    
    @IBOutlet var PrivacyTap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        navigationController?.navigationBar.prefersLargeTitles = true;
        
        UserPicture.layer.cornerRadius = UserPicture.frame.size.width/2;
        UserPicture.clipsToBounds = true;
        
        UserTeams.isUserInteractionEnabled = false;
        UserTeams.contentView.alpha = 0.43;
        
        UserLogged = true
        do{
        let retrievedSettings = try Disk.retrieve("UserData/Settings.json", from: .applicationSupport, as: Settings.self)
            autoSetWinnerSwitch.setOn(retrievedSettings.autoSetMatchWinner, animated: false)
        }
        catch{
            autoSetWinnerSwitch.setOn(true, animated: false)
            
            let settings = Settings(autoSetMatchWinner: true)
            do{
            try Disk.save(settings, to: .applicationSupport, as: "UserData/Settings.json")
            }catch{
                print("COŚ POSZŁO NIE TAK - NIE MOŻNA ZAPISAĆ USTAWIEŃ DOMYŚLNYCH")
            }
        }
        
        if KeychainWrapper.standard.string(forKey: "USER_LOGIN") != nil {
            UserData.text = KeychainWrapper.standard.string(forKey: "USER_LOGIN");
            UserPicture.isHidden = false;
            UserTeams.isUserInteractionEnabled = true;
            UserTeams.contentView.alpha = 1;
            UserTeams.isUserInteractionEnabled = false;
            UserTeams.contentView.alpha = 0.43;
            
            UserLogged = true;
            do{
                UserPicture.image = try Disk.retrieve("UserData/UserImage.png", from: .caches, as: UIImage.self)
            }catch{
                UserPicture.image = #imageLiteral(resourceName: "Person-Placeholder")
            }
            
        }else{
            UserData.text = NSLocalizedString("login", comment: "Please log in");
            UserPicture.isHidden = true;
            UserTeams.isUserInteractionEnabled = false;
            UserTeams.contentView.alpha = 0.43;
            UserLogged = false;
            print("USER NOT LOGGED IN")
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func PictureTapped(_ sender: UITapGestureRecognizer) {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        var image: UIImage!
        if let selectedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage{
            image = selectedImage
        }else if let selectedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage{
            image = selectedImage
        } else{
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        UserPicture.image = image
        do{
            try Disk.save(image, to: .caches, as: "UserData/UserImage.png")
        }catch{
            fatalError("Couldn't save user's image")
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func LoginTapped(_ sender: UITapGestureRecognizer) {
        
        if UserLogged{
            let alert = UIAlertController(title: nil, message: NSLocalizedString("logoutMessage", comment: "Are you sure you want to log out?"), preferredStyle: .actionSheet);
            alert.addAction(UIAlertAction(title: NSLocalizedString("logout", comment: "Log out"), style: .destructive, handler: { (action) -> Void in
                KeychainWrapper.standard.removeObject(forKey: "USER_LOGIN")
                KeychainWrapper.standard.removeObject(forKey: "USER_PASS")
                self.switchLogin()
                self.viewDidAppear(true)
            }));
            if let popover = alert.popoverPresentationController{
                popover.sourceView = self.view
                popover.sourceRect = UserData.frame
            }
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancelAction", comment: "Cancel the action"), style: .default));
            self.present(alert, animated: true, completion: nil);
        }else{
            loginAlert = UIAlertController(title: NSLocalizedString("loginTitle", comment: "Title for logging in screen"), message: NSLocalizedString("loginMessage", comment: "Loggining in message"), preferredStyle: .alert);
            
            loginAlert.addTextField(configurationHandler: { (loginField) -> Void in
                loginField.placeholder = NSLocalizedString("username", comment: "Username");
                loginField.textAlignment = .center;
                loginField.addTarget(self, action: #selector(self.enableLoginButton(_:)), for: .editingChanged);
            })
            loginAlert.addTextField(configurationHandler: { (passwordField) -> Void in
                passwordField.placeholder = NSLocalizedString("password", comment: "Password");
                passwordField.isSecureTextEntry = true;
                passwordField.textAlignment = .center;
                passwordField.addTarget(self, action: #selector(self.enableLoginButton(_:)), for: .editingChanged);
            });
            let okAction = UIAlertAction(title: NSLocalizedString("login", comment: "Log in"), style: .default, handler: { (action) -> Void in
                
                let hash = self.loginAlert.textFields![1].text!.sha256().uppercased()
                
                let params = ["username": self.loginAlert.textFields![0].text!, "password": hash]
                API.login(parameters: params, callback: {(error) in
                    if error != nil{
                        print("ERROR")
                        print(error)
                        DispatchQueue.main.async {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            self.dismiss(animated: true, completion: nil)
                            let newMessage = NSAttributedString(string: NSLocalizedString("invalidLogin", comment: "Wrong usernamen or password"), attributes:convertToOptionalNSAttributedStringKeyDictionary([
                                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor.red
                                ]))
                            self.loginAlert.message = ""
                            self.loginAlert.setValue(newMessage, forKey: "attributedMessage")
                            self.present(self.loginAlert, animated: true, completion: nil)
                        }
                    }else{
                        DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        KeychainWrapper.standard.set(self.loginAlert.textFields![0].text!, forKey:"USER_LOGIN")
                        KeychainWrapper.standard.set(hash, forKey: "USER_PASS")
                        self.UserPicture.image = #imageLiteral(resourceName: "Person-Placeholder")
                        do{
                            try Disk.save(#imageLiteral(resourceName: "Person-Placeholder"), to: .caches, as: "UserData/UserImage.png")
                        }catch{
                            fatalError("Couldn't save user's image")
                        }
                        self.switchLogin()
                        }
                    }
                })
                self.viewDidAppear(true)
            })
            
            okAction.isEnabled = false;
            loginAlert.addAction(okAction);
            loginAlert.addAction(UIAlertAction(title: NSLocalizedString("cancelAction", comment: "Cancel"), style: .cancel, handler: nil));
            self.present(loginAlert, animated: true, completion: nil);
        }
        
    }
    
    @objc func enableLoginButton(_ sender: UITextField){
        loginAlert.actions[0].isEnabled = loginAlert.textFields![0].text!.count > 0 && loginAlert.textFields![1].text!.count > 0
    }
    
    func switchLogin(){
        UserLogged = !UserLogged
        if UserLogged {
            UserData.text = KeychainWrapper.standard.string(forKey: "USER_LOGIN");
            UserPicture.isHidden = false;
        }else{
            UserData.text = NSLocalizedString("login", comment: "Please, log in");
            UserPicture.isHidden = true;
        }
    }
    
    @IBAction func changeAutoWinner(_ sender: UISwitch) {
        do{
            var retrievedSettings = try Disk.retrieve("UserData/Settings.json", from: .applicationSupport, as: Settings.self)
            
            retrievedSettings.autoSetMatchWinner = autoSetWinnerSwitch.isOn
            
            try Disk.save(retrievedSettings, to: .applicationSupport, as: "UserData/Settings.json")
        }catch{
            autoSetWinnerSwitch.setOn(!autoSetWinnerSwitch.isOn, animated: true)
        }
    
    }
    @IBAction func facebookTapped(_ sender: UITapGestureRecognizer) {
        let fbURL = URL(string: "https://www.facebook.com/events/547305495801058/")
        UIApplication.shared.open(fbURL! , options: [:], completionHandler: nil)
        
    }
    @IBAction func privacyTapped(_ sender: UITapGestureRecognizer) {
        let privacyURL = URL(string: "https://mmaterek.nazwa.pl/kormoran/privacy_pl.html")
        UIApplication.shared.open(privacyURL! , options: [:], completionHandler: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
