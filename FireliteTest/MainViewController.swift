//
//  MainViewController.swift
//  FireliteTest
//
//  Created by Alexandre Ménielle on 21/01/2018.
//  Copyright © 2018 Alexandre Ménielle. All rights reserved.
//

import UIKit
import CoreData
import Firelite
import Firebase

class MainViewController: UIViewController {

    @IBOutlet weak var firstnameTextfield: UITextField!
    @IBOutlet weak var lastnameTextfield: UITextField!
    @IBOutlet weak var usersTableview: UITableView!
    
    var context: NSManagedObjectContext?
    var ref = Database.database().reference()
    let fireliteEntity = FireliteEntity()

    let entities = ["User":"users",
                    "Store":"stores",
                    "Product":"products",
                    "Operator":"operators"]
    
    var users : [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Home"
        usersTableview.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        syncCoredataToFirebase()
    }
    
    func printAllUsers(){
        print("\n-------------- ALL USERS --------------")
        print(users)
        print("---------------------------------------\n")
    }
    
    func syncCoredataToFirebase(){
        
        guard let context = self.context else { return }
        for entity in entities{
            
            ref.child(entity.value).observe(.childAdded, with: { (snapshot) in
                if let json = snapshot.value as? [String:Any]{
                    self.fireliteEntity.coreDataSave(context: context, dictionnary: json, entityName: entity.key)
                    try? self.context?.save()
                }
            })
            
            //Update coredata entity at each firebase modifications
            ref.child(entity.value).observe(.childChanged, with: { (snapshot) in
                if let json = snapshot.value as? [String:Any]{
                    self.fireliteEntity.coreDataSave(context: context, dictionnary: json, entityName: entity.key)
                    try? self.context?.save()
                }
            })
            
            /*ref.child(entity.value).observe(.value, with: { (snapshot) in
                if let json = snapshot.value as? [String:Any]{
                    self.fireliteEntity.coreDataSave(context: context, dictionnary: json, entityName: entity.key)
                    try? self.context?.save()
                    self.printAllUsers()
                }
            })*/
            
            //Delete coredata entity
            ref.child(entity.value).observe(.childRemoved, with: { (snapshot) in
                if let json = snapshot.value as? [String:Any]{
                    self.fireliteEntity.coreDataSave(method: .delete, context: context, dictionnary: json, entityName: entity.key)
                    try? self.context?.save()
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onValidateUser(_ sender: Any) {
        
        guard
            let firstname = firstnameTextfield.text,
            let lastname = lastnameTextfield.text
        else { return }
        
        let key = ref.childByAutoId().key
        ref.child("users").child(key).updateChildValues(["firstname":firstname, "lastname": lastname, "id": key])
    }
}

extension MainViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Array(entities.keys).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        let entity = Array(entities.keys)[indexPath.row]
        
        cell.modelNameLabel.text = entity
        cell.nextImg.isHidden = false
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()

        let objectVC = ObjectViewController()
        objectVC.entityName = Array(entities.keys)[indexPath.row]
        objectVC.context = self.context
        objectVC.entities = self.entities
        self.navigationController?.pushViewController(objectVC, animated: true)
    }
}
