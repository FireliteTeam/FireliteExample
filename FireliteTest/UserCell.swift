//
//  UserCell.swift
//  FireliteTest
//
//  Created by Alexandre Ménielle on 29/01/2018.
//  Copyright © 2018 Alexandre Ménielle. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var checkView: UIView!
    @IBOutlet weak var nextImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        selectedView.layer.cornerRadius = selectedView.frame.width / 2
        checkView.layer.cornerRadius = checkView.frame.width / 2
    }
    
}
