//
//  FormCell.swift
//  FireliteTest
//
//  Created by Alexandre Ménielle on 03/02/2018.
//  Copyright © 2018 Alexandre Ménielle. All rights reserved.
//

import UIKit

class FormCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var nextImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
