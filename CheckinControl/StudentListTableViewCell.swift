//
//  StudentListTableViewCell.swift
//  CheckinControl
//
//  Created by Xuanzhe Zhu on 2019/11/26.
//  Copyright © 2019 XuanzheZhu. All rights reserved.
//

import UIKit

class StudentListTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var studentIDLabel: UILabel!
    @IBOutlet weak var registerStatusLabel: UILabel!
    @IBOutlet weak var checkinStatusLabel: UILabel!
    @IBOutlet weak var checkinTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
