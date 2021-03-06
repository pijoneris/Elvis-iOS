//
//  SearchedBooksController.swift
//  Elvis
//
//  Created by Benas on 22/03/2019.
//  Copyright © 2019 RM-Elvis. All rights reserved.
//

import UIKit


class SearchedBooksController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    var isNightModeEnabled = false
    var noDataLabel: UILabel?
    var books : [AudioBook] = []
    var lineHeight : Int = 40
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600
        
    }
    
    @IBAction func changeContrast(_ sender: Any) {
        toggleMode()
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func enableDarkMode(){
        isNightModeEnabled = true
        
        let cells = self.tableView.visibleCells as! Array<AudioBookCell>
        for cell in cells {
            cell.enableNightMode()
        }
        self.noDataLabel?.textColor = UIColor.white
        self.tableView.backgroundColor = UIColor.black
        self.view.backgroundColor = UIColor.black
        
        
    }
    override func disableDarkMode(){
        isNightModeEnabled = false
        
        let cells = self.tableView.visibleCells as! Array<AudioBookCell>
        for cell in cells {
            cell.disableNightMode()
        }
        
        self.noDataLabel?.textColor = UIColor.black
        self.tableView.backgroundColor = UIColor.white
        self.view.backgroundColor = UIColor.white
    }
    
}




extension SearchedBooksController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    /*
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
 */
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audioBookCurrent : AudioBook = books[indexPath.row]
        let cell : AudioBookCell = tableView.dequeueReusableCell(withIdentifier: "AudioBookCell") as! AudioBookCell
        cell.setUpCell(audioBook: audioBookCurrent, viewController: self, session: Utils.readFromSharedPreferences(key: "sessionID") as! String)
        cell.delegate = self
        cell.indexPath = indexPath
        isNightModeEnabled ? cell.enableNightMode() : cell.disableNightMode()
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if(books.count == 0){
            noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel!.text          = "Knygų nerasta"
            noDataLabel!.textColor     = isNightModeEnabled ? UIColor.white : UIColor.black
            noDataLabel!.textAlignment = .center
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }else{
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
        }
        return 1
    }
    
    func removeBook(at: IndexPath){
        print("index: " + String(at.row))
        self.books.remove(at: at.row)
        self.tableView.deleteRows(at: [at], with: .automatic)
        self.tableView.reloadData()
    }
}
