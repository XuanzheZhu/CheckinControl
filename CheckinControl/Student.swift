//
//  StudentList.swift
//  CheckinControl
//
//  Created by Xuanzhe Zhu on 2019/11/26.
//  Copyright © 2019 XuanzheZhu. All rights reserved.
//

import UIKit

class Student {
    
    //MARK: Properties
    var studentID: String
    var registerStatus: Bool
    var checkinStatus: Bool
    var checkinTime: String
    
    //MARK: Initialization
    init?(studentID: String, registerStatus: Bool, checkinStatus: Bool, checkinTime: String) {
        
        guard !studentID.isEmpty else {
            return nil
        }
        
        self.studentID = studentID
        self.registerStatus = registerStatus
        self.checkinStatus = checkinStatus
        self.checkinTime = checkinTime
        
    }
    
}
