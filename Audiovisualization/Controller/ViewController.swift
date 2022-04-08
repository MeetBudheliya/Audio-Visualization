//
//  ViewController.swift
//  Audiovisualization
//
//  Created by Meet Budheliya on 07/04/22.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var WaveFormView: UIView!
    
    var audioRecorder:AVAudioRecorder!
    let recFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 22050, channels: 1, interleaved: true)
    var timer : Timer!
    
    //temp url
    let recordingURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("rec.wav"))
    
    // bezire path inside he waveform.bounds
    lazy var pencil = UIBezierPath(rect: WaveFormView.bounds)
    //first point
    lazy var firstPoint = CGPoint(x: 6, y: (WaveFormView.bounds.midY))
    //jump
    lazy var jump : CGFloat = (WaveFormView.bounds.width - (firstPoint.x * 2)) / 200
    //shapelayer
    let waveLayer = CAShapeLayer()
    //traitLength
    var traitLength:CGFloat!
    //start
    var start:CGPoint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioRecorder = AVAudioRecorder()
        
    }
    
    // MARK: - Start Recording Button Clicked
    @IBAction func StartRecordingButtonClicked(_ sender: UIButton) {
        self.PrepareRecording()
    }
    
    // MARK: - Prepare For Recording
    func PrepareRecording(){
        do{
            try AVAudioSession.sharedInstance().setCategory(.record,mode: .default,options: .allowBluetooth)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.enableBuiltInMic()
            
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if allowed{
                        self.startRecording()
                    }else{
                        //mic disabled
                        print("MIC DISABLED")
                    }
                }
            }
        }catch{
            // failed to record
        }
    }
    
    // MARK: - Enable BuiltIn Mic
    func enableBuiltInMic(){
        // Get the shared audio session.
        let session = AVAudioSession.sharedInstance()
        // Find the built-in microphone input.
        guard let availableInputs = session.availableInputs,
              let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
                  print("The device must have a built-in microphone.")
                  return
              }
        // Make the built-in microphone input the preferred input.
        do {
            try session.setPreferredInput(builtInMicInput)
        } catch {
            print("Unable to set the built-in mic as the preferred input.")
        }
    }
    
    func startRecording(){
        pencil.removeAllPoints()
        waveLayer.removeFromSuperlayer()
                writeWaves(0, false)
        
        do{
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recFormat!.settings)
            audioRecorder.record(forDuration: 4)
            audioRecorder.isMeteringEnabled = true
        }catch{
            //errors handled here
            print("errors handled here")
        }
        
        var counterTimer = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true, block: { time in
            if counterTimer == 200{
                self.writeWaves(0, false)
            }
            
            self.audioRecorder.updateMeters()
            
            //Write Waveforms
            self.writeWaves((self.audioRecorder.averagePower(forChannel: 0)), true)
            
            counterTimer += 1
        })
    }
    
    func writeWaves(_ input: Float, _ bool : Bool) {
        if !bool {
            start = firstPoint
            if timer != nil || audioRecorder != nil{
                timer.invalidate()
                audioRecorder.stop()
            }
            return
            
        } else {
            if input < -55
            {
                traitLength = 0.2
            }
            else if input < -40 && input > -55
            {
                traitLength = (CGFloat(input)+56)/3
            }
            else if input < -20 && input > -48
            {
                traitLength = (CGFloat(input)+41)/2
            }
            else if input < -10 && input > -20
            {
                traitLength = (CGFloat(input)+21)*5
            }
            else
            {
                traitLength = (CGFloat(input)+20)*4
            }
            pencil.lineWidth = jump
            pencil.move(to: start)
            pencil.addLine(to: CGPoint(x: start.x, y: start.y + traitLength))
            pencil.move(to: start)
            pencil.addLine(to: CGPoint(x: start.x, y: start.y - traitLength))
            waveLayer.strokeColor = UIColor.black.cgColor
            waveLayer.path = pencil.cgPath
            waveLayer.fillColor = UIColor.clear.cgColor
            
            waveLayer.lineWidth = jump
            WaveFormView.layer.addSublayer (waveLayer)
            waveLayer.contentsCenter = WaveFormView.frame
            WaveFormView.setNeedsDisplay()
            start = CGPoint(x: start.x + jump, y: start.y)
        }
        
    }
}
