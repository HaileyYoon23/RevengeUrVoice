//
//  EditViewController.swift
//  RevengeUrVoice
//
//  Created by 나윤서 on 2021/03/06.
//

import UIKit

class EditViewController: UIViewController {

    @IBOutlet var txtTalkFor: UITextField!
    @IBOutlet var txtToTalk: UITextField!
    
    static var talkFor: String?
    static var toTalk: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let talkInfo = TalkInfoDB.readTalkInfo() {
            txtTalkFor.text = talkInfo.talkFor
            txtToTalk.text = talkInfo.toTalk
        } else {
            txtTalkFor.text = ""
            txtToTalk.text = ""
        }
    }
    
    @IBAction func btnSave(_ sender: UIButton) {
        if TalkInfoDB.readTalkInfo() != nil {
            TalkInfoDB.updateTalkInfo(talkFor: txtTalkFor.text ?? "", toTalk: txtToTalk.text ?? "")
        } else {
            _ = TalkInfoDB.insertTalkInfo(talkFor: txtTalkFor.text ?? "", toTalk: txtToTalk.text ?? "")
        }
        
        EditViewController.talkFor = txtTalkFor.text
        EditViewController.toTalk = txtToTalk.text
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
