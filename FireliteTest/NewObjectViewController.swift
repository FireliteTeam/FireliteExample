//
//  NewObjectViewController.swift
//  FireliteTest
//
//  Created by Alexandre Ménielle on 03/02/2018.
//  Copyright © 2018 Alexandre Ménielle. All rights reserved.
//

import UIKit
import CoreData
import Firebase

class NewObjectViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    
    var context: NSManagedObjectContext?
    var entity : NSEntityDescription?
    var attributes : [(key:String,value:NSAttributeType)] = []
    var relationships : [(key:String,value:NSEntityDescription?)] = []
    var lastSelectedIndex = 0
    var object : NSManagedObject?
    
    var dict : [String:Any] = [:]
    var entities : [String:String] = [:]
    var id = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "New Object"
        guard let name = entity?.name else { return }
        self.title = "New " + name
        
        if let object = self.object {
            
            if let id = object.value(forKey: "id") as? String{
                self.id = id
            }
            
            self.title = "Change " + name
            for relationship in relationships {
                var values : [String:Any] = [:]
                if let relationObjects = (object.value(forKey: relationship.key) as? NSSet)?.allObjects as? [NSManagedObject]{
                    for relationObject in relationObjects {
                        if let id = relationObject.value(forKey: "id") as? String {
                            values[id] = true
                        }
                    }
                    dict[relationship.key] = values
                }else if let relationObject = object.value(forKey: relationship.key) as? NSManagedObject{
                    if let id = relationObject.value(forKey: "id") as? String {
                        dict[relationship.key] = id
                    }
                }
            }
        }else{
            id = Database.database().reference().childByAutoId().key
        }
        
        tableview.register(UINib(nibName: "FormCell", bundle: nil), forCellReuseIdentifier: "FormCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onValidate(_ sender: Any) {
        for i in 0..<(attributes.count+relationships.count){
            if let cell = tableview.cellForRow(at: IndexPath(row: i, section: 0)) as? FormCell{
                if i < attributes.count {
                    //TODO faire pour chaque type
                    switch attributes[i].value {
                    case .stringAttributeType:
                        dict[attributes[i].key] = cell.textField.text
                        break
                    case .doubleAttributeType:
                        dict[attributes[i].key] = Double(cell.textField.text ?? "")
                        break
                    case .floatAttributeType:
                        dict[attributes[i].key] = Float(cell.textField.text ?? "")
                        break
                    case .integer16AttributeType:
                        dict[attributes[i].key] = Int(cell.textField.text ?? "")
                        break
                        
                    default:
                        break
                    }
                    
                }
            }
        }
        let ref = Database.database().reference()
        if let entityName = entity?.name, let firebaseEntity = entities[entityName] {
            ref.child(firebaseEntity).child(id).updateChildValues(dict)
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension NewObjectViewController : UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributes.count + relationships.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell", for: indexPath) as? FormCell else {
            return UITableViewCell()
        }
        
        if indexPath.row < attributes.count {
            cell.selectionStyle = .none
            var type = "(unknow)"
            switch attributes[indexPath.row].value {
            case .stringAttributeType:
                type = "(String)"
                break
            case .doubleAttributeType:
                type = "(Double)"
                break
            case .floatAttributeType:
                type = "(Float)"
                break
            case .integer16AttributeType:
                type = "(Int)"
                break
                
            default:
                break
            }
            
            cell.textField.isUserInteractionEnabled = true
            if attributes[indexPath.row].key == "id" {
                cell.textField.isUserInteractionEnabled = false
                if id != "" {
                    cell.textField.text = id
                }
            }
            
            if let value = object?.value(forKey: attributes[indexPath.row].key) {
                cell.textField.text = "\(value)"
            }
            
            cell.textField.placeholder = "\(attributes[indexPath.row].key) \(type)"
            cell.textField.isHidden = false
            cell.nextImg.isHidden = true
        }else{
            cell.selectionStyle = .blue
            cell.textField.isHidden = true
            cell.label.text = relationships[indexPath.row - attributes.count].key
            cell.nextImg.isHidden = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
        if indexPath.row >= attributes.count, let entityName = relationships[indexPath.row - attributes.count].value?.name {
            lastSelectedIndex = indexPath.row
            let objectVC = ObjectViewController()
            objectVC.entityName = entityName
            objectVC.context = self.context
            objectVC.delegate = self
            let relationship = relationships[indexPath.row - attributes.count]
            if let values = dict[relationship.key] as? [String:Bool] {
                objectVC.selectedObject = values
            }else if let values = dict[relationship.key] as? String {
                objectVC.selectedObject = [values:true]
            }
            if let maxCount = entity?.relationshipsByName[relationship.key]?.maxCount {
                if maxCount == 1 {
                    //to One
                    objectVC.toOne = true
                }else{
                    //to Many
                    objectVC.toOne = false
                }
            }
            self.navigationController?.pushViewController(objectVC, animated: true)
        }
    }
}

extension NewObjectViewController : SelectObjectDelegate {
    
    func selectObject(values: [String:Bool], toOne : Bool) {
        let relationShip = relationships[lastSelectedIndex - attributes.count]
        if toOne {
            if let value = values.keys.first {
                dict[relationShip.key] = value
            }else {
                dict[relationShip.key] = nil
            }
            return
        }
        dict[relationShip.key] = values
    }
}
