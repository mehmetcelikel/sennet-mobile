//
//  NewSearchTVC.swift
//  semnet
//
//  Created by ceyda on 16/12/16.
//  Copyright © 2016 celikel. All rights reserved.
//

import UIKit

class NewSearchTVC: UITableViewController, UISearchBarDelegate {

    var searchBar = UISearchBar()
    
    var allUsersArray = [SemNetUser]()//user
    
    var userArray = [SemNetUser]()//user
    var allSemanticLabels = [SemanticLabel]()
    var semanticLabelArray = [SemanticLabel]()
    
    var initialView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = false
        
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor.groupTableViewBackground
        searchBar.frame.size.width = self.view.frame.size.width - 34
        
        let cancelButtonAttributes: NSDictionary = [NSForegroundColorAttributeName: UIColor.black]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes as? [String : AnyObject], for: UIControlState.normal)
        
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = searchItem
        
        let authToken = UserManager.sharedInstance.getToken()
        
        UserManager.sharedInstance.loadUserlist(token: authToken!) { (response) in
            if(response.0){
                self.allUsersArray = response.1
                self.userArray = self.allUsersArray
                self.tableView.reloadData()
            }
        }
        
        SearchManager.sharedInstance.getAllTags() { (response) in
            if(response.0){
                self.allSemanticLabels = response.1
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if(initialView){
            return allSemanticLabels.count
        }
        
        return userArray.count + semanticLabelArray.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! NewSearchTVCell
        
        var upperLabel = ""
        var lowerLabel = ""
        
        if(initialView){
            let semLabel = allSemanticLabels[indexPath.row]
            upperLabel = semLabel.tag + "(" + semLabel.clazz + ")"
            
            if(semLabel.count > 1){
                lowerLabel = String(semLabel.count) + " posts"
            }else{
                lowerLabel = String(semLabel.count) + " post"
            }
            
            cell.searchImageView.image = UIImage(named: "users.png")!
            
        }else{
            
            if(indexPath.row < semanticLabelArray.count){
                let semLabel = semanticLabelArray[indexPath.row]
                
                upperLabel = semLabel.tag + "(" + semLabel.clazz + ")"
                
                cell.searchImageView.image = UIImage(named: "users.png")!
            }else{
                let object = userArray[indexPath.row-semanticLabelArray.count]
                
                lowerLabel = "@" + object.username
                upperLabel = object.firstname + " " + object.lastname
                
                cell.user = object
                
                UserManager.sharedInstance.downloadImage(userId: object.id){ (response) in
                    
                    if(response.0){
                        cell.searchImageView.image=response.1
                    }
                }
            }
        }
        
        cell.usernameLabel.text = lowerLabel
        cell.fullNameLabel.text = upperLabel
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if(initialView){
            
            let home = self.storyboard?.instantiateViewController(withIdentifier: "AppHomeVC") as! AppHomeVC
            home.action = "SemanticSearch"
            home.selectedTag = allSemanticLabels[indexPath.row]
            
            self.navigationController?.pushViewController(home, animated: true)
            
        }else{
            
            if(indexPath.row >= semanticLabelArray.count){
                
                let object = userArray[indexPath.row-semanticLabelArray.count]
                
                profileUserId.append(object.id)
                let guest = self.storyboard?.instantiateViewController(withIdentifier: "ProfileCVC") as! NewProfileVC
                self.navigationController?.pushViewController(guest, animated: true)
            }else{
                
                let home = self.storyboard?.instantiateViewController(withIdentifier: "AppHomeVC") as! AppHomeVC
                home.action = "SemanticSearch"
                home.selectedTag = semanticLabelArray[indexPath.row]
                
                self.navigationController?.pushViewController(home, animated: true)
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // scroll down
        if scrollView.contentOffset.y >= scrollView.contentSize.height / 6 {
            
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let home = self.storyboard?.instantiateViewController(withIdentifier: "AppHomeVC") as! AppHomeVC
        home.action = "SemanticSearch"
        
        var label = SemanticLabel(tag: searchBar.text!, clazz: nil)
        
        home.selectedTag = label
        
        self.navigationController?.pushViewController(home, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.initialView = false
        
        self.tableView.isHidden = false
        searchBar.showsCancelButton = true
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        self.initialView = true
        
        // self.tableView.isHidden = true
        // dismiss keyboard
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        
        searchBar.text = ""
        
        self.userArray = self.allUsersArray
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let resultArray = filterUsers(searchText: searchText)
        userArray = resultArray
        
        SearchManager.sharedInstance.getTags(queryString: searchText){ (response) in
            if(response.0){
                self.semanticLabelArray=response.1
            }else{
                self.semanticLabelArray.removeAll()
            }
            self.tableView.reloadData()
        }
    }

    func filterUsers(searchText: String) -> [SemNetUser]{
        var resultArray = [SemNetUser]()
        
        for object in allUsersArray {
            
            if(searchText.characters.count == 0){
                resultArray.append(object)
            }else{
                
                let result1 = Tools.levenshtein(aStr: searchText.uppercased(), bStr: object.username.uppercased())
                let r1 = result1+(searchText.characters.count) - object.username.characters.count
                if(r1 <= 0) {
                    resultArray.append(object)
                }else{
                    let fullname = object.firstname + " " + object.lastname
                    let result2 = Tools.levenshtein(aStr: searchText.uppercased(), bStr: fullname.uppercased())
                    
                    let r2 = result2+(searchText.characters.count) - fullname.characters.count
                    
                    if(r2 <= 0) {
                        resultArray.append(object)
                    }
                }
            }
        }
        return resultArray
    }
}
