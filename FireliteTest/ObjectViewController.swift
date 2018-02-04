//
//  ObjectViewController.swift
//  FireliteTest
//
//  Created by Alexandre Ménielle on 03/02/2018.
//  Copyright © 2018 Alexandre Ménielle. All rights reserved.
//

import UIKit
import CoreData

protocol SelectObjectDelegate: class {
    func selectObject(values: [String:Bool], toOne : Bool)
}

class ObjectViewController: UIViewController {
    
    @IBOutlet weak var bottomTableviewConstraint: NSLayoutConstraint!
    @IBOutlet weak var validBtn: UIButton!
    @IBOutlet weak var tableview: UITableView!
    var entityName = ""
    var entities : [String:String] = [:]
    var context: NSManagedObjectContext?
    var objects : [NSManagedObject] = []
    var delegate : SelectObjectDelegate?
    var selectedObject : [String:Bool] = [:]
    var toOne = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = entityName
        tableview.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        
        if delegate != nil && toOne == false{
            validBtn.isHidden = false
            bottomTableviewConstraint.constant = validBtn.frame.height
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if objects.count == 0 {
            fetchEntity(entityName: entityName)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addObject))
        }
    }
    
    @objc func addObject(){
        guard let context = self.context, let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { return }
        let attributes = entity.attributesByName.map({ (key: $0.key,value: $0.value.attributeType)})
        let relationships = entity.relationshipsByName.map({ (key: $0.key,value: $0.value.destinationEntity)})

        let newObjectVC = NewObjectViewController()
        newObjectVC.entity = entity
        newObjectVC.context = self.context
        newObjectVC.attributes = attributes
        newObjectVC.relationships = relationships
        newObjectVC.entities = self.entities
        self.navigationController?.pushViewController(newObjectVC, animated: true)
    }
    
    func fetchEntity(entityName : String){
        
        guard let context = self.context else { return }
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: entityName)
        if let managedObjects = try? context.fetch(request) {
            self.objects = managedObjects
            tableview.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onValidBtn(_ sender: Any) {
        guard let delegate = self.delegate else { return }
        delegate.selectObject(values: selectedObject, toOne: toOne)
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension ObjectViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(section)"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let object = objects[section]
        let attributes =  object.entity.attributesByName.map({ (key: $0.key,value: $0.value.attributeType)})
        let relationships = object.entity.relationshipsByName.map({ (key: $0.key,value: $0.value.destinationEntity)})
        return attributes.count + relationships.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        let object = objects[indexPath.section]
        let attributes =  object.entity.attributesByName.map({ (key: $0.key,value: $0.value.attributeType)})
        let relationships = object.entity.relationshipsByName.map({ (key: $0.key,value: $0.value.destinationEntity)})

        var text = ""
        if indexPath.row < attributes.count {
            text = "\(attributes[indexPath.row].key) : "
            if let value = object.value(forKey: attributes[indexPath.row].key) {
                text += "\(value)"
            }else{
                text += "null"
            }
            cell.checkView.isHidden = true
            cell.selectedView.isHidden = true
            cell.nextImg.isHidden = true
            if delegate != nil && attributes[indexPath.row].key == "id"{
                cell.selectedView.isHidden = false
                if let id = object.value(forKey: "id") as? String, selectedObject[id] != nil {
                    cell.checkView.isHidden = false
                }
            }else if attributes[indexPath.row].key == "id" {
                cell.nextImg.isHidden = false
            }
        }else{
            text = relationships[indexPath.row - attributes.count].key
            cell.nextImg.isHidden = false
        }
        
        cell.modelNameLabel.text = text
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
        
        let object = objects[indexPath.section]
        let attributes =  object.entity.attributesByName.map({ (key: $0.key,value: $0.value.attributeType)})
        let relationships = object.entity.relationshipsByName.map({ (key: $0.key,value: $0.value.destinationEntity)})

        if indexPath.row >= attributes.count {
            if let values = (object.value(forKey: relationships[indexPath.row - attributes.count].key) as? NSSet)?.allObjects as? [NSManagedObject]{
                let objectVC = ObjectViewController()
                objectVC.entityName = relationships[indexPath.row - attributes.count].value?.name ?? ""
                objectVC.objects = values
                objectVC.context = self.context
                self.navigationController?.pushViewController(objectVC, animated: true)
            }else if let value = object.value(forKey: relationships[indexPath.row - attributes.count].key) as? NSManagedObject {
                let objectVC = ObjectViewController()
                objectVC.entityName = relationships[indexPath.row - attributes.count].value?.name ?? ""
                objectVC.objects = [value]
                objectVC.context = self.context
                self.navigationController?.pushViewController(objectVC, animated: true)
            }
        }else if attributes[indexPath.row].key == "id", let id = object.value(forKey: attributes[indexPath.row].key) as? String{
            if let delegate = self.delegate {
                if selectedObject[id] == nil {
                    if toOne {
                        selectedObject.removeAll()
                    }
                    selectedObject[id] = true
                }else{
                    selectedObject[id] = nil
                }
                if toOne{
                    delegate.selectObject(values: selectedObject, toOne: toOne)
                    self.navigationController?.popViewController(animated: true)
                }
            }else{
                guard let context = self.context, let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { return }
                let attributes = entity.attributesByName.map({ (key: $0.key,value: $0.value.attributeType)})
                let relationships = entity.relationshipsByName.map({ (key: $0.key,value: $0.value.destinationEntity)})
                
                let newObjectVC = NewObjectViewController()
                newObjectVC.entity = entity
                newObjectVC.context = self.context
                newObjectVC.attributes = attributes
                newObjectVC.relationships = relationships
                newObjectVC.entities = self.entities
                newObjectVC.object = objects[indexPath.section]
                self.navigationController?.pushViewController(newObjectVC, animated: true)
            }
        }
    }
}
