//
//  ViewController.swift
//  CheckinControl
//
//  Created by Xuanzhe Zhu on 2019/11/19.
//  Copyright © 2019 XuanzheZhu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, StreamDelegate {
    
    //MARK: Properties
    //Socket server
    let addr = "10.180.107.248"
    let port = 9876
    
    //Network variables
    var inStream : InputStream?
    var outStream: OutputStream?
    
    //Data received
    var buffer = [UInt8](repeating: 0, count: 200)
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: Button Actions
    func btnSwitchToRegisterPressed() {
        let strToSend = "register"
        outStream?.write(strToSend, maxLength: strToSend.utf8.count)
        //let bytesWritten = message.withUnsafeBytes { outStream?.write($0, maxLength: message.count) }
    }
    func btnSwitchToCheckinPressed() {
        let strToSend = "checkin"
        outStream?.write(strToSend, maxLength: strToSend.utf8.count)
    }
    
    // MARK: Network Actions
    func NetworkEnable() {
        print("NetworkEnable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
        inStream?.delegate = self
        outStream?.delegate = self
        
        inStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        outStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        
        inStream?.open()
        outStream?.open()
        
        buffer = [UInt8](repeating: 0, count: 200)
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
