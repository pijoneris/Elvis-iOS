//
//  MainScreenController.swift
//  Elvis
//
//  Created by Benas on 22/03/2019.
//  Copyright © 2019 RM-Elvis. All rights reserved.
//
import UIKit
import SVProgressHUD
import RealmSwift


class MainScreenController: BaseViewController {
    
    let preferences = UserDefaults.standard
    
    @IBOutlet weak var listenHistoryBtn: UIButton!
    @IBOutlet weak var searchBooksBtn: UIButton!
    @IBOutlet weak var newestPublicationsBtn: UIButton!
    @IBOutlet weak var messagesBtn: UIButton!
    @IBOutlet weak var downloadsBtn: UIButton!
    
    
    @IBAction func changeTheme(_ sender: Any) {
        toggleMode()
        
    }
    
    @IBAction func recentBooks(_ sender: Any) {
        let books: [AudioBook] = Array(DatabaseUtils.getRecentBooks())
        //passing data and going to new view controller
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "SearchedBooks") as! SearchedBooksController
        newViewController.books = books
        self.present(newViewController, animated: true, completion: nil)
        print(books.count)
    }
    override func viewDidLoad() {
        applyAccesibility()
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        //Utils.writeToSharedPreferences(key: "sessionID", value: "DummySessionID")
    }
    
    @IBAction func back(_ sender: Any) {
       confirmationMessage(message: "Ar tikrai norite atsijungti?", viewController: self)
    }
    
    @IBAction func newestBooks(_ sender: Any) {
        let disabilities = Utils.readFromSharedPreferences(key: "haveDisabilities") as! String
        SVProgressHUD.show(withStatus: "Ieškoma naujausių knygų")
        SVProgressHUD.setDefaultMaskType(.black)
        
        DatabaseUtils.NewestBooks(haveDisabilities: disabilities, onFinishListener: {
           (books, success) in
            
            SVProgressHUD.dismiss()
            guard success else{
                SVProgressHUD.showError(withStatus: "Klaida!")
                return
            }
            
            if(books.isEmpty){
                Utils.alertMessage(message: "Nerasta naujų knygų", title: "Klaida", buttonTitle: "Bandyti dar kartą!", viewController: self)
                return
            }
            //passing data and going to new view controller
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "SearchedBooks") as! SearchedBooksController
            newViewController.books = books
            self.present(newViewController, animated: true, completion: nil)
            
        })
        
    }
    
    @IBAction func seeDownloads(_ sender: Any) {
        let books: [AudioBook] = Array(DatabaseUtils.getDownloadedBooks())
        //passing data and going to new view controller
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "SearchedBooks") as! SearchedBooksController
        newViewController.books = books
        self.present(newViewController, animated: true, completion: nil)
        print(books.count)
    }
    
    @IBAction func showMessages(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "Messages") as! MessagesViewController
        self.present(newViewController, animated: true, completion: nil)
    }
    
    
    func confirmationMessage(message:String, viewController: UIViewController){
        // Declare Alert message
        let dialogMessage = UIAlertController(title: "Atsijungti!", message: message, preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "Gerai", style: .default, handler: { (action) -> Void in
            viewController.dismiss(animated: true, completion: nil)
            DatabaseUtils.clearData()
            
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Atšaukti!", style: .cancel) { (action) -> Void in
            
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        viewController.present(dialogMessage, animated: true, completion: nil)
    }
    
    override func enableDarkMode(){
        searchBooksBtn.backgroundColor = UIColor.clear
        searchBooksBtn.setTitleColor(.white, for: .normal)
        
        listenHistoryBtn.backgroundColor = UIColor.clear
        listenHistoryBtn.setTitleColor(.white, for: .normal)
        
        newestPublicationsBtn.backgroundColor = UIColor.clear
        newestPublicationsBtn.setTitleColor(.white, for: .normal)
        
        messagesBtn.backgroundColor = UIColor.clear
        messagesBtn.setTitleColor(.white, for: .normal)
        
        downloadsBtn.backgroundColor = UIColor.clear
        downloadsBtn.setTitleColor(.white, for: .normal)
        
        self.view.backgroundColor = UIColor.black
        
    }
    override func disableDarkMode(){
        searchBooksBtn.backgroundColor = UIColor.clear
        searchBooksBtn.setTitleColor(.black, for: .normal)
        
        listenHistoryBtn.backgroundColor = UIColor.clear
        listenHistoryBtn.setTitleColor(.black, for: .normal)
        
        newestPublicationsBtn.backgroundColor = UIColor.clear
        newestPublicationsBtn.setTitleColor(.black, for: .normal)
        
        messagesBtn.backgroundColor = UIColor.clear
        messagesBtn.setTitleColor(.black, for: .normal)
        
        downloadsBtn.backgroundColor = UIColor.clear
        downloadsBtn.setTitleColor(.black, for: .normal)
        
        self.view.backgroundColor = UIColor.white
    }
    
    
}

extension MainScreenController{
    func applyAccesibility(){
        
        listenHistoryBtn.isAccessibilityElement = true
        listenHistoryBtn.accessibilityLabel = "Klausymų istorija"
        listenHistoryBtn.accessibilityTraits = .button
        
        searchBooksBtn.isAccessibilityElement = true
        searchBooksBtn.accessibilityLabel = "Knygų paieška"
        searchBooksBtn.accessibilityTraits = .button
        
        newestPublicationsBtn.isAccessibilityElement = true
        newestPublicationsBtn.accessibilityLabel = "Naujausi leidiniai"
        newestPublicationsBtn.accessibilityTraits = .button
        
        messagesBtn.isAccessibilityElement = true
        messagesBtn.accessibilityLabel = "Žinutės ir naujienos"
        messagesBtn.accessibilityTraits = .button
        
        downloadsBtn.isAccessibilityElement = true
        downloadsBtn.accessibilityLabel = "Parsiųstos knygos"
        downloadsBtn.accessibilityTraits = .button
        
        
    }

    
}
