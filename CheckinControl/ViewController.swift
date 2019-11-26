//
//  ViewController.swift
//  CheckinControl
//
//  Created by Xuanzhe Zhu on 2019/11/19.
//  Copyright © 2019 XuanzheZhu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, StreamDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    //Socket server
    let addr = "10.180.146.206"
    let port = 9876
    
    // Network variables
    var inStream : InputStream?
    var outStream: OutputStream?
    
    // Data received
    var buffer = [UInt8](repeating: 0, count: 200)
    
    // Student list variables
    var status = 1; // register->0, checkin->1
    var studentList: [Student] = []
    
    @IBAction func connectServer(_ sender: Any) {
        NetworkEnable()
    }
    
    @IBAction func switchToRegisterMode(_ sender: Any) {
        btnSwitchToRegisterPressed()
    }
    
    @IBAction func switchToCheckinMode(_ sender: Any) {
        btnSwitchToCheckinPressed()
    }
    
    @IBOutlet weak var statusBox: UILabel!
    @IBOutlet weak var studentListTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        studentListTable.delegate = self
        studentListTable.dataSource = self

        // Temporary values for testing
        guard let student1 = Student(studentID: "111", registerStatus: false, checkinStatus: false) else {
            fatalError("Unable to add student 1")
        }
        guard let student2 = Student(studentID: "222", registerStatus: false, checkinStatus: false) else {
            fatalError("Unable to add student 2")
        }
        studentList += [student1, student2]
    }
    
    // MARK: Student List Table Setup
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "StudentCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? StudentListTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let student = studentList[indexPath.row]
        cell.studentIDLabel.text = student.studentID
        cell.registerStatusLabel.text = student.registerStatus ? "True" : "False"
        cell.checkinStatusLabel.text = student.checkinStatus ? "True" : "False"
        
        return cell
    }
    
    // MARK: Button Actions
    func btnSwitchToRegisterPressed() {
        sendMessage(strToSend: "register")
        status = 0
        studentList[0].registerStatus = true
        DispatchQueue.main.async { self.studentListTable.reloadData() }
    }
    func btnSwitchToCheckinPressed() {
        sendMessage(strToSend: "checkin")
        status = 1
    }
    
    // MARK: Network Actions
    func sendMessage(strToSend: String) {
        outStream?.write(strToSend, maxLength: strToSend.utf8.count)
    }
    
    func NetworkEnable() {
        print("NetworkEnable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
        inStream?.delegate = self
        outStream?.delegate = self
        
        inStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        outStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        
        inStream?.open()
        outStream?.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.endEncountered:
            print("EndEncountered")
            statusBox.text = "Connection stopped by server"
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            outStream?.close()
            print("Stop outStream currentRunLoop")
            outStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        case Stream.Event.errorOccurred:
            print("ErrorOccurred")
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            outStream?.close()
            outStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            statusBox.text = "Failed to connect to server"
        case Stream.Event.hasBytesAvailable:
            print("HasBytesAvailable")
            if aStream == inStream {
                buffer = [UInt8](repeating: 0, count: 200)
                inStream!.read(&buffer, maxLength: buffer.count)
                let bufferStr = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                print(bufferStr!)
                statusBox.text = bufferStr! as String
            }
        case Stream.Event.hasSpaceAvailable:
            print("HasSpaceAvailable")
        case Stream.Event.openCompleted:
            print("OpenCompleted")
            statusBox.text = "Connected to server"
        default:
            print("Unknown")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
