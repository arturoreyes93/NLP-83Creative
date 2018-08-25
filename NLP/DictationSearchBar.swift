//
//  DictationSearchBar.swift
//  NLP
//
//  Created by Arturo Reyes on 8/24/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import UIKit
import Speech

protocol UIRecordingDelegate: class {
    func enableRecordingUI()
}

protocol SpeechRecordingDelegate: class {
    func didFinishRecordingWithResult()
}

class DictationSearchBar: UISearchBar, SFSpeechRecognizerDelegate {
    
    var uiRecordingDelegate: UIRecordingDelegate?
    var recordingDelegate: SpeechRecordingDelegate?
    var stopButtonPressed = false
    let microphoneButton = UIButton(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
    let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
    var searchField: UITextField!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    var request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        if let textFieldIndex = getSearchFieldIndex() {
            searchField = (subviews[0].subviews[textFieldIndex]) as! UITextField
            searchField.textColor = .black
            searchField.backgroundColor = .white
            setMicrophoneButton()
            searchField.rightView = microphoneButton
            searchField.rightViewMode = .unlessEditing
        }
        
        
        self.isTranslucent = true
        self.backgroundImage = UIImage()
        self.backgroundColor = .white
        self.barTintColor = .clear
        
        activityIndicator.color = .gray
        
        
    }
    
    func getSearchFieldIndex() -> Int? {
        for view in subviews[0].subviews {
            if view is UITextField {
                return subviews[0].subviews.index(of: view)
            }
        }
        return nil
    }
    
    func setMicrophoneButton() {
        microphoneButton.setImage(#imageLiteral(resourceName: "record_100"), for: .normal)
        microphoneButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        microphoneButton.adjustsImageWhenDisabled = true
        microphoneButton.adjustsImageWhenHighlighted = true
        microphoneButton.addTarget(self, action: #selector(startRecording(_:)), for: .touchUpInside)
    }
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            // Recognizer is not supported for the current locale
            return
        }
        
        if !myRecognizer.isAvailable {
            // Recognizer is not available
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
            if let result = result {
                let resultString = result.bestTranscription.formattedString
                self.text = resultString
                
                if self.stopButtonPressed {
                    self.beginStopTimer()
                }
                
            } else if let error = error {
                print(error)
            }
        })
    }
    
    func beginStopTimer() {
        let _ = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(stopRecordingAndSearch), userInfo: nil, repeats: false)
    }
    
    @objc func stopRecordingAndSearch() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request = SFSpeechAudioBufferRecognitionRequest()
        recordingDelegate?.didFinishRecordingWithResult()
        
        DispatchQueue.main.async {
            self.searchField.rightView = self.microphoneButton
            self.activityIndicator.stopAnimating()
        }
    }
    
    @objc func startRecording(_ sender: UIButton) {
        stopButtonPressed = false
        uiRecordingDelegate?.enableRecordingUI()
        recordAndRecognizeSpeech()
        
    }
    
    

}

class CustomSearchController: UISearchController {
    
    var dictationSearchBar: DictationSearchBar!

    override init(searchResultsController: UIViewController?) {
        super.init(searchResultsController: searchResultsController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.dictationSearchBar = DictationSearchBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
