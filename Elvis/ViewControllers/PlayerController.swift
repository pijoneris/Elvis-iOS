//
//  PlayerController.swift
//  Elvis
//
//  Created by Benas on 26/03/2019.
//  Copyright © 2019 RM-Elvis. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation


class PlayerController: BaseViewController {

    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    var timer : Timer?
    var timerRunning : Bool = false;
    let seekDuration: Float64 = 50
    
    var book: AudioBook!
    var chapters : [String]!
    var selectedChapterIndex : Int = 0
    var selectedChapter: String?
    var sessionID: String?
    var isLocal: Bool = false;
    var isFast: Bool = false;
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var skipBack: UIButton!
    @IBOutlet weak var fastBackwards: UIButton!
    @IBOutlet weak var fastForwards: UIButton!
    @IBOutlet weak var skipForward: UIButton!
    
    
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var tv_bookTitle: UILabel!
    @IBOutlet weak var tv_time: UILabel!
    @IBOutlet weak var chapterTextField: UITextField!
    
    
    @IBAction func changeContrast(_ sender: Any) {
        toggleMode()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        applyAccesibility()
        chapters = createChapters(book: book)
        sessionID = Utils.readFromSharedPreferences(key: "sessionID") as! String
        
        progressSlider.addTarget(self, action: #selector(PlayerController.playbackSliderValueChanged(_:)), for: .valueChanged)
        
        tv_bookTitle.text = book.Title
        createDayPicker()
    }

    
    @IBAction func play(_ sender: Any) {
        
        if(player==nil){
            let finalUrl: URL!
            let chapter = isFast ? book.FileFastIDS[selectedChapterIndex] : book.FileNormalIDS[selectedChapterIndex]
            if(isLocal){
                let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                finalUrl = documentsDirectoryURL.appendingPathComponent(chapter + ".mp3")
            }else{
                let url1 = "http://elvis.labiblioteka.lt/publications/getmediafile/" + chapter
                let url2 = "/" + chapter + ".mp3?session_id=" + sessionID!
                finalUrl = URL(string: (url1 + url2))
            }
            
             playAudioBook(url: finalUrl)
            playButton.setImage(UIImage(named: "Pause"), for: .normal)
            print(finalUrl)

             return
        }
        if(player?.rate == 0){
            player?.play()
            timerRunning = true;
            playButton.setImage(UIImage(named: "Pause"), for: .normal)
        }else{
            timerRunning = false;
            playButton.setImage(UIImage(named: "Play"), for: .normal)
            player?.pause()
        }
    }
    
    @IBAction func fastForward(_ sender: Any) {
        if(player?.rate != 0){
         
            guard let duration  = player?.currentItem?.duration else{
                return
            }
            let playerCurrentTime = CMTimeGetSeconds((player?.currentTime())!)
            let newTime = playerCurrentTime + seekDuration
            
            if newTime < CMTimeGetSeconds(duration) {
                
                let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                let cTime = Float(time2.seconds)
                player?.seek(to: time2)
                tv_time.text = timeLabelSetter(seconds: Int(cTime))
                progressSlider.setValue(Float(cTime), animated: true)
            }
        }
    }
    
    @IBAction func fastBackwards(_ sender: Any) {
        
        if(player?.rate != 0){
            let playerCurrentTime = CMTimeGetSeconds((player?.currentTime())!)
            var newTime = playerCurrentTime - seekDuration
        
            if newTime < 0 {
                newTime = 0
            }
            
            let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
            let cTime = Float(time2.seconds)
            player?.seek(to: time2)
            tv_time.text = timeLabelSetter(seconds: Int(cTime))
            progressSlider.setValue(Float(cTime), animated: true)
        }
    }
    
    
    
    @IBAction func skipForward(_ sender: Any) {
        if(player?.rate != 0){
            player?.pause()
            player = nil
            player?.rate = 0
            timer!.invalidate()
            timer = nil
            progressSlider.setValue(0, animated: true)
            tv_time.text = "0:00"
    
            var nextChapter: Int = selectedChapterIndex + 1
           
            if(nextChapter > (book.FileCount/2)-1){
                nextChapter = 0;
                
            }
            chapterTextField.text = "SKIRSNIS:" + String(nextChapter+1)
            selectedChapterIndex = nextChapter
            playButton.sendActions(for: .touchUpInside)
            
        }
        
    }

    @IBAction func skipPrevious(_ sender: Any) {
        
        if(player?.rate != 0){
            player?.pause()
            player = nil
            player?.rate = 0
            timer!.invalidate()
            timer = nil
            progressSlider.setValue(0, animated: true)
            tv_time.text = "0:00"
            
            var nextChapter: Int = selectedChapterIndex - 1
            
            if(nextChapter < 0){
                nextChapter = (book.FileCount/2)-1;
                
            }
            chapterTextField.text = "SKIRSNIS:" + String(nextChapter+1)
            selectedChapterIndex = nextChapter
            playButton.sendActions(for: .touchUpInside)
            
        }
        
    }
    
    @IBAction func back(_ sender: Any) {
    
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        
        player?.pause()
        player?.rate = 0
        dismiss(animated: true, completion: nil)
    }
    
    func playAudioBook(url: URL){
        let playerItem:AVPlayerItem = AVPlayerItem(url: url)
        
        let seconds : Float64 = CMTimeGetSeconds(playerItem.asset.duration)
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = Float(seconds)
        progressSlider.isContinuous = true
        progressSlider.tintColor = UIColor.orange
        
        timer =  Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        timerRunning = true;
    }
    
    
    //Creates array of all possible chapters: NOT IMPORTANT
    func createChapters(book: AudioBook) -> [String]{
        var chapterArray : [String] = []
        var x: Int = 0;
        while x < book.FileCount/2{
            let chapter: String = "SKIRSNIS: " + String(x+1)
            chapterArray.append(chapter)
            x = x + 1
        }
        return chapterArray
    }
    
    //House keeping stuff fro dayPicker: Not IMPORTANT
    func createDayPicker() {
        let dayPicker = UIPickerView()
        dayPicker.delegate = self
        chapterTextField.inputView = dayPicker
        
        dayPicker.backgroundColor = .orange
    
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        toolBar.barTintColor = .orange
        toolBar.tintColor = .white
        
        let doneButton = UIBarButtonItem(title: "Baigti", style: .plain, target: self, action: #selector(PlayerController.dismissPicker))
        
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        chapterTextField.inputAccessoryView = toolBar
    }
    
    func timeLabelSetter(seconds: Int) -> String{
        var builder: String = ""
        let mins: Int = seconds/60;
        let secs: Int = seconds - mins*60;
        if(secs<10){
            builder = "" + String(mins) + ":" + "0" + String(secs)
        }else{
            builder = "" + String(mins) + ":" + String(secs)
        }
        return builder
    }
    
    //Triggers when you dismiss the selector
    @objc func dismissPicker() {
        progressSlider.setValue(0, animated: true)
        tv_time.text = "0:00"
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        if(player?.rate != 0){
            playButton.setImage(UIImage(named: "Play"), for: .normal)
            player?.pause()
            player?.rate = 0
            player = nil
        }
        print(selectedChapterIndex)
        view.endEditing(true)
    }
    
    @objc func playbackSliderValueChanged(_ playbackSlider:UISlider){
        
        if(player == nil){
            return
        }
        
        let seconds : Int64 = Int64(playbackSlider.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        
        
        player!.seek(to: targetTime)
        
        if player!.rate == 0
        {
            player?.play()
        }
    }
    
    @objc func timerAction(){
        if(timerRunning){
            let value = progressSlider.value
            progressSlider.setValue(value+1, animated: true)
            tv_time.text = timeLabelSetter(seconds: Int(value))
            tv_time.accessibilityValue = tv_time.text
        }
    }
 
    
    override func enableDarkMode(){
        tv_bookTitle.textColor = UIColor.white
        tv_time.textColor = UIColor.white
        chapterTextField.backgroundColor = UIColor.clear
        chapterTextField.textColor = UIColor.white
        chapterTextField.borderWidth = 3
        chapterTextField.borderColor = UIColor.white
        
        playButton.tintColor = UIColor.white
        skipBack.tintColor = UIColor.white
        fastBackwards.tintColor = UIColor.white
        fastForwards.tintColor = UIColor.white
        skipForward.tintColor = UIColor.white
        
        self.view.backgroundColor = UIColor.black
        
    }
    override func disableDarkMode(){
        tv_bookTitle.textColor = UIColor.black
        tv_time.textColor = UIColor.black
        chapterTextField.backgroundColor = UIColor.clear
        chapterTextField.borderWidth = 3
        chapterTextField.borderColor = UIColor.black
        chapterTextField.textColor = UIColor.black
        
        playButton.tintColor = UIColor.black
        skipBack.tintColor = UIColor.black
        fastBackwards.tintColor = UIColor.black
        fastForwards.tintColor = UIColor.black
        skipForward.tintColor = UIColor.black
        
        self.view.backgroundColor = UIColor.white
    }

    
}


//Chapter picker view: SLIGHTLY IMPORTANT
extension PlayerController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return chapters.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return chapters[row]
    }
    
    
    //This triggers when you try to select new stuff
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedChapter = chapters[row]
        selectedChapterIndex = row
        chapterTextField.text = selectedChapter
        
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var label: UILabel
        
        if let view = view as? UILabel {
            label = view
        } else {
            label = UILabel()
        }
        
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "Menlo-Regular", size: 25)
        
        label.text = chapters[row]
        
        label.isAccessibilityElement = true
        return label
    }
    
   
}


extension PlayerController{
    func applyAccesibility(){
      
        tv_bookTitle.isAccessibilityElement = true
        tv_bookTitle.accessibilityLabel = "Book name"
        tv_bookTitle.accessibilityValue = book.Title
        
        chapterTextField.isAccessibilityElement = true
        chapterTextField.accessibilityTraits = UIAccessibilityTraits.button
        chapterTextField.accessibilityLabel = "Select book chapter"
        chapterTextField.accessibilityValue = "Chapter selector apears at the bottom"
        
        tv_time.isAccessibilityElement = true
        tv_time.accessibilityLabel = "Time"
        tv_time.accessibilityValue = tv_time.text
        
        progressSlider.isAccessibilityElement = true
        progressSlider.accessibilityLabel = "Time slider"
        progressSlider.accessibilityValue = "Change current time"
        
    }
}
