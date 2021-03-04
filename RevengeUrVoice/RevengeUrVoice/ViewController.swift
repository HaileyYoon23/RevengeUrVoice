//
//  ViewController.swift
//  RevengeUrVoice
//
//  Created by 나윤서 on 2021/03/04.
//

import UIKit
import Speech

// Available upper iOS 10.0
class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var txtSpeechToTextView: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var recordingWord = false
    
    private var prevText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        speechRecognizer?.delegate = self
        let checkSelecor = #selector(ViewController.checkState)
//        _ = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: checkSelecor, userInfo: nil, repeats: true)
    }
    
    @objc func checkState() {
        prevText = txtSpeechToTextView.text

    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            btnRecord.isEnabled = true
        } else {
            btnRecord.isEnabled = false
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.txtSpeechToTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                print(isFinal)
                self.recordingWord = true
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.btnRecord.isEnabled = true
            }
        })
        
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        txtSpeechToTextView.text = "Say something, I'm listening!"
        
    }

    @IBAction func RecognitionStart(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            btnRecord.isEnabled = false
            btnRecord.backgroundColor = UIColor.lightGray
        } else {
            startRecording()
            btnRecord.backgroundColor = UIColor.white
        }
    }
    
}

