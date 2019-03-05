//
//  MeczeTableViewCell.swift
//  Kormoran Beach Party ScoreAdmin
//
//  Created by Administrator on 03.07.2017.
//  Copyright © 2017 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import UIKit

class MeczeTableViewCell: UITableViewCell {

    @IBOutlet weak var player1Name: UILabel!
    @IBOutlet weak var player2Name: UILabel!
    @IBOutlet weak var Score: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
