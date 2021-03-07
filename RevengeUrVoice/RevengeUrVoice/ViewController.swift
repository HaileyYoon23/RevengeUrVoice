//
//  ViewController.swift
//  RevengeUrVoice
//
//  Created by 나윤서 on 2021/03/04.
//

import UIKit
import Speech
import AVFoundation

extension NSMutableAttributedString {
    func emphasize(_ text: String, fontSize: CGFloat) -> NSMutableAttributedString {
        let attribute: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: fontSize)]
        self.append(NSMutableAttributedString(string: text + " ", attributes: attribute))
        return self
    }
    func normal(_ text: String, fontSize: CGFloat) -> NSMutableAttributedString {
        let attribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize)]
        self.append(NSMutableAttributedString(string: text + " ", attributes: attribute))
        
        return self
    }
}

// Available upper iOS 10.0
class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var txtSpeechToTextView: UITextView!
    @IBOutlet var lblAlramToTalkFor: UILabel!
    
    private var words: String?
    private var prevWords: String?
    private var combinedWords: String = ""
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var recordingWord = false
    
    private var wordList: [Substring] = [Substring]()
    private var showingString = NSMutableAttributedString()
    private var wordCount: Int = 0
    private var prevWordCount: Int = 0
    private var endRecord: Bool = false
    private var restartRecord: Bool = false
    private var isSaid : Bool = false
    
    private var talkinfo = TalkInfo(talkFor: "", toTalk: "")
    let DB = TalkInfoDB()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        speechRecognizer?.delegate = self
        
        
        btnRecord.backgroundColor = UIColor.lightGray
        
        
        let checkSelecor = #selector(ViewController.checkState)
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: checkSelecor, userInfo: nil, repeats: true)
        
        
    }
    
    @objc func checkState() {
        if let talkInfoItem = TalkInfoDB.readTalkInfo() {
            talkinfo = talkInfoItem
        }
        
        lblAlramToTalkFor.text = "'\(talkinfo.talkFor )' 에  '\(talkinfo.toTalk )' 로 대응"
//        if combinedWords == "" {
//            txtSpeechToTextView.text = "아래 버튼을 누루고 말하기 시작하세요!"
//        }
//        print("\(words) \(prevWords) \(txtSpeechToTextView.text)")
        if let theWord = words {
            showingString = NSMutableAttributedString()
            if let pW = prevWords {
                combinedWords = pW + " " + theWord
                wordList = combinedWords.split(separator: " ")
            } else {
                combinedWords = theWord
                wordList = combinedWords.split(separator: " ")
            }
            
            wordCount = 0
            for str in wordList {
                if str == (talkinfo.talkFor) {
                    showingString = showingString.emphasize(String(str), fontSize: 17.0)
                    wordCount += 1
                } else {
                    showingString = showingString.normal(String(str), fontSize: 15.0)
                }
            }
            txtSpeechToTextView.attributedText = showingString
        }
        if prevWordCount != wordCount && restartRecord == false {
            if audioEngine.isRunning {
                prevWordCount = wordCount
                endRecord = true
            }
        }
        if endRecord {
            if audioEngine.isRunning {
//                print("isEnding")
                if isSaid == false && (words ?? "") != "" {
                    self.view.backgroundColor = UIColor.lightGray
                    usleep(UInt32(1000*400))
                }
                audioEngine.stop()
                audioEngine.reset()
                recognitionRequest?.endAudio()
                recognitionTask?.cancel()
                btnRecord.isEnabled = false
//                btnRecord.backgroundColor = UIColor.lightGray
                showingString = NSMutableAttributedString()
                words = String()
                endRecord = false
                restartRecord = true
                
            }
        }
        if restartRecord {
            if audioEngine.isRunning == false && btnRecord.isEnabled == true{
//                print("isRestarting")
                if (words ?? "") != "" {
                    if let pW = prevWords {
                        prevWords = pW + " " + words!
                    } else {
                        prevWords = words!
                    }
                    sayTheWord(theWord: talkinfo.toTalk )
                    usleep(UInt32(1000*300*((talkinfo.toTalk ).count)))
                    isSaid = true
                } else {
                    self.view.backgroundColor = UIColor.white
                    isSaid = false
                }
                do {
                    try startRecording()
                } catch {
                    print("error?")
                }
                restartRecord = false
            }
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            btnRecord.isEnabled = true
        } else {
            btnRecord.isEnabled = false
        }
    }
    
    func startRecording() throws {
        btnRecord.backgroundColor = UIColor.white
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.default) //AVAudioSessionModeDefault
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
                self.words = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                self.recordingWord = true
            } else {
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
        
        
    }
    
    func sayTheWord(theWord: String) {
        let syntehesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: theWord)
        
        utterance.voice = AVSpeechSynthesisVoice(language: "ko_KR")
        utterance.rate = 0.4
//        utterance.pitchMultiplier = 0.5 // 작아질 수록 낮은 목소리
        syntehesizer.speak(utterance)
        do{
            let _ = try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
                                                                    options: .duckOthers)
          }catch{
              print(error)
          }
    }

    @IBAction func RecognitionStart(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.reset()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            btnRecord.isEnabled = false
            btnRecord.backgroundColor = UIColor.lightGray
            showingString = NSMutableAttributedString()
            words = String()
        } else {
            prevWordCount = 0
            wordCount = 0
            do {
                try startRecording()
            } catch {
                print("error~")
            }
            
            
        }
    }
}

