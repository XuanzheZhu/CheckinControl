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
    let addr = "172.20.10.3"
    let port = 9876
    
    // Network variables
    var inStream : InputStream?
    var outStream: OutputStream?
    
    // Data received
    var buffer = [UInt8](repeating: 0, count: 200)
    
    // Student list variables
    var status = 1; // register->0, checkin->1
    var studentList: [Student] = []
    
    let documentInteractionController = UIDocumentInteractionController()
    private let docDirPath:NSString = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString).appendingPathComponent("StudentList.csv") as NSString
    
    lazy var manager:FileManager = {
        return FileManager.default
    }()
    
    @IBAction func connectServer(_ sender: Any) {
        NetworkEnable()
    }
    
    @IBAction func saveCheckinStatus(_ sender: Any) {
        saveCheckinTable(withURLString: docDirPath as String)
    }
    
    @IBAction func switchToRegisterMode(_ sender: Any) {
        btnSwitchToRegisterPressed()
    }
    
    @IBAction func switchToCheckinMode(_ sender: Any) {
        btnSwitchToCheckinPressed()
    }
    
    @IBAction func clearRegisterStatus(_ sender: Any) {
        sendMessage(strToSend: "clearRegister")
        for student in studentList {
            student.registerStatus = false
            student.checkinStatus = false
            student.checkinTime = "不可用"
        }
        refreshTable()
    }
    
    @IBAction func clearCheckinStatus(_ sender: Any) {
        sendMessage(strToSend: "clearCheckin")
        for student in studentList {
            student.checkinStatus = false
            student.checkinTime = "不可用"
        }
        refreshTable()
    }
    
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusBox: UILabel!
    @IBOutlet weak var studentListTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        studentListTable.delegate = self
        studentListTable.dataSource = self
        
        documentInteractionController.delegate = self

        guard self.manager.fileExists(atPath: docDirPath as String) else {
            fatalError("No student list file")
        }
        let studentStr = String(decoding: self.manager.contents(atPath: docDirPath as String)!, as: UTF8.self)
        let studentArray = studentStr.components(separatedBy: "\n")
        for student in studentArray {
            if student.lengthOfBytes(using: .utf8) < 2 {
                break
            }
            let tempStudent = student.components(separatedBy: ",")
            if tempStudent[0] == "学号" {
                continue
            }
            guard let newStudent = Student(studentID: tempStudent[0], registerStatus: tempStudent[1] == "已注册" ? true : false, checkinStatus: false, checkinTime: "不可用") else {
                fatalError("Error when retrive student from list")
            }
            studentList += [newStudent]
        }
    }
    
    // MARK: Student List Table Setup
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentList.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "StudentCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? StudentListTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        if indexPath.row > 0 {
            let student = studentList[indexPath.row - 1]
            cell.studentIDLabel.text = student.studentID
            cell.registerStatusLabel.text = student.registerStatus ? "已注册" : "未注册"
            cell.checkinStatusLabel.text = student.checkinStatus ? "已签到" : "未签到"
            cell.checkinTime.text = student.checkinTime
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            sendMessage(strToSend: studentList[indexPath.row - 1].studentID)
        }
    }
    
    func refreshTable() {
        DispatchQueue.main.async { self.studentListTable.reloadData() }
    }
    
    // MARK: Button Actions
    func btnSwitchToRegisterPressed() {
        sendMessage(strToSend: "register")
        status = 0
        statusLabel.text = "状态：注册模式"
    }
    func btnSwitchToCheckinPressed() {
        sendMessage(strToSend: "checkin")
        status = 1
        statusLabel.text = "状态：签到模式"
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
                updateList(message: bufferStr! as String)
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
    
    // MARK: Private Methods
    func updateList(message: String) {
        let possibleStudentID = message.components(separatedBy: " ")[0]
        let possibleIDInteger: Int? = Int(possibleStudentID)
        if possibleIDInteger != nil {
            if status == 0 {
                for student in studentList {
                    if student.studentID == possibleStudentID {
                        student.registerStatus = true
                    }
                }
            }
            else if status == 1 {
                let date = Date()
                let format = DateFormatter()
                format.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let formattedDate = format.string(from: date)
                for student in studentList {
                    if student.studentID == possibleStudentID {
                        student.checkinStatus = true
                        student.checkinTime = formattedDate
                    }
                }
            }
            refreshTable()
            refreshListFile()
        }
    }
    
    func refreshListFile() {
        var strToWrite: String = "学号,注册状态,签到状态,签到时间\n"
        for student in studentList {
            var tempStrToWrite: String = ""
            tempStrToWrite += (student.studentID + "," + (student.registerStatus == true ? "已注册" : "未注册") + "," + (student.checkinStatus == true ? "已签到" : "未签到") + "," + student.checkinTime + "\n")
            strToWrite += tempStrToWrite
        }
        try! self.manager.removeItem(atPath: docDirPath as String)
        let data: Data? = strToWrite.data(using: .utf8)
        self.manager.createFile(atPath: docDirPath as String, contents: data, attributes: nil)
    }

}

extension ViewController {
    /// This function will set all the required properties, and then provide a preview for the document
    func share(url: URL) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentPreview(animated: true)
    }
    
    /// This function will store your document to some temporary URL and then provide sharing, copying, printing, saving options to the user
    func saveCheckinTable(withURLString: String) {
        let url = NSURL.fileURL(withPath: withURLString)
        // guard let url = URL(string: withURLString) else { return }
        /// START YOUR ACTIVITY INDICATOR HERE
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(response?.suggestedFilename ?? "filename.txt")
            do {
                try data.write(to: tmpURL)
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                /// STOP YOUR ACTIVITY INDICATOR HERE
                self.share(url: tmpURL)
            }
            }.resume()
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
