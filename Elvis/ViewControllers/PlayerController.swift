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
import MediaPlayer
import SVProgressHUD


class PlayerController: BaseViewController {

    
    var nowPlayingInfo = [String : Any]()
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    var timer : Timer?
    var timerRunning : Bool = false;
    let seekDuration: Float64 = 50
    
    var book: AudioBook!
    var chapters : [String]!
    var selectedChapterIndex : Int = 0
    var selectedChapter: String = "Skirsnis: 1"
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
        print(book.FileNormalIDS)
        
        progressSlider.isHidden = true
        progressSlider.isContinuous = true
        progressSlider.tintColor = UIColor.orange
        
        sessionID = Utils.readFromSharedPreferences(key: "sessionID") as! String
        progressSlider.addTarget(self, action: #selector(PlayerController.playbackSliderValueChanged(_:)), for: .valueChanged)
        
        tv_bookTitle.text = book.Title
        createDayPicker()
        
        configureAudioSession()
        setupMediaPlayerNotificationView()
        setupNotificationView(currentChapter: chapters[selectedChapterIndex])
    }
    
    @objc func playbackSliderValueChanged(_ playbackSlider:UISlider){
        timerRunning = false
        tv_time.text = timeLabelSetter(seconds: Int(playbackSlider.value))
        tv_time.accessibilityValue = tv_time.text
        
    }
    
    @IBAction func ProggresSliderFinishedChanging(_ sender: UISlider) {
       
        guard player != nil else {return}

        let targetTime:CMTime = CMTimeMake(value: Int64(sender.value), timescale: 1)
        setNotificationPlayerTime(playBackRate: 0, elapsedTime: Float(CMTimeGetSeconds((player?.currentTime())!)))
        
        player?.seek(to: targetTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (isCompleted) in
            self.timerRunning = true
            self.setNotificationPlayerTime(playBackRate: 1, elapsedTime: Float(CMTimeGetSeconds((self.player?.currentTime())!)))
            
            if(self.player?.rate == 0){
                self.player?.play()
                self.timerRunning = true
                self.playButton.setImage(UIImage(named: "Pauze"), for: .normal)
            }
        })
        
    }
    @IBAction func play(_ sender: Any) {
        progressSlider.isHidden = false
        
        if(player==nil){
            playAudioBook(url: createUrl())
            return
        }
        
        playerToggler()
    }
    
    func playerToggler(){
        if(!playerIsPlaying()){
            player?.play()
            timerRunning = true;
            playButton.setImage(UIImage(named: "Pauze"), for: .normal)
            self.setNotificationPlayerTime(playBackRate: 1, elapsedTime: Float(CMTimeGetSeconds((self.player?.currentTime())!)))
            
        }else{
            timerRunning = false;
            playButton.setImage(UIImage(named: "Groti"), for: .normal)
            player?.pause()
            self.setNotificationPlayerTime(playBackRate: 0, elapsedTime: Float(CMTimeGetSeconds((self.player?.currentTime())!)))
        }
    }
    
    @IBAction func fastForward(_ sender: Any) {
        if(playerIsPlaying()){
            
            guard let duration  = player?.currentItem?.duration else{
                return
            }
            timerRunning = false
            let playerCurrentTime = CMTimeGetSeconds((player?.currentTime())!)
            let newTime = playerCurrentTime + seekDuration
            
            if newTime < CMTimeGetSeconds(duration) {
                
                let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                let cTime = Float(time2.seconds)
                
                player?.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (isCompleted) in
                    self.setNotificationPlayerTime(playBackRate: 1, elapsedTime: Float(CMTimeGetSeconds((self.player?.currentTime())!)))
                    self.tv_time.text = self.timeLabelSetter(seconds: Int(cTime))
                    self.progressSlider.setValue(Float(cTime), animated: true)
                    self.timerRunning = true
                })
                
                
            }
        }
    }
    
    @IBAction func fastBackwards(_ sender: Any) {
        
        if(playerIsPlaying()){
            
            guard let duration = player?.currentItem?.duration else{return}
               
            timerRunning = false
            
            let playerCurrentTime = CMTimeGetSeconds((player?.currentTime())!)
            var newTime = playerCurrentTime - seekDuration
        
            if newTime < 0 {
                newTime = 0
            }
            
            let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
            let cTime = Float(time2.seconds)
            
            player?.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (isCompleted) in
                self.setNotificationPlayerTime(playBackRate: 1, elapsedTime: Float(CMTimeGetSeconds((self.player?.currentTime())!)))
                self.tv_time.text = self.timeLabelSetter(seconds: Int(cTime))
                self.progressSlider.setValue(Float(cTime), animated: true)
                self.timerRunning = true
        
            })
        }
    }
    
    @IBAction func skipForward(_ sender: Any) {
     
        if(player != nil){
            player?.pause()
            player = nil
            player?.rate = 0
        }
        
            stopPlayerControllerTimer()
            progressSlider.setValue(0, animated: true)
            tv_time.text = "0:00"
    
            var nextChapter: Int = selectedChapterIndex + 1
           
            if(nextChapter > (book.FileCount/2)-1){
                nextChapter = 0;
                
            }
        
            chapterTextField.text = "SKIRSNIS:" + String(nextChapter+1)
            selectedChapterIndex = nextChapter
            playButton.sendActions(for: .touchUpInside)
        
            setNotificationPlayerTime(playBackRate: 0, elapsedTime: Float(CMTimeGetSeconds(CMTime.zero)))
        
    }

    @IBAction func skipPrevious(_ sender: Any) {
        
        if(player != nil){
            
            player?.pause()
            player = nil
            player?.rate = 0
            
        }
            stopPlayerControllerTimer()
            
            progressSlider.setValue(0, animated: true)
            tv_time.text = "0:00"
            
            var nextChapter: Int = selectedChapterIndex - 1
            if(nextChapter < 0){
                nextChapter = (book.FileCount/2)-1;
                
            }
            chapterTextField.text = "SKIRSNIS:" + String(nextChapter+1)
            selectedChapterIndex = nextChapter
        
            playButton.sendActions(for: .touchUpInside)
            setNotificationPlayerTime(playBackRate: 0, elapsedTime: Float(CMTimeGetSeconds(CMTime.zero)))
    }
    
    func createUrl() -> URL{
        let finalUrl: URL!
        let chapter = isFast ? book.FileFastIDS[selectedChapterIndex] : book.FileNormalIDS[selectedChapterIndex]
        if(isLocal){
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            finalUrl = documentsDirectoryURL.appendingPathComponent(chapter + ".mp3")
        }else{
            let url1 = "http://elvis.labiblioteka.lt/publications/getmediafile/" + chapter
            let url2 = "/" + chapter + ".mp3?session_id=" + sessionID!
            finalUrl = URL(string: (url1 + url2))
            print(finalUrl)
        }
        
        return finalUrl
    }
    
    @IBAction func back(_ sender: Any) {
    
        stopPlayerControllerTimer()
        
        player?.pause()
        player?.rate = 0
        dismiss(animated: true, completion: nil)
    }
    
    func setupMediaPlayerNotificationView(){
        
        let commandCenter = MPRemoteCommandCenter.shared()
         UIApplication.shared.beginReceivingRemoteControlEvents()
        
        
        // Scrubber
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self](remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}
            if let player = self.player {
                let playerRate = player.rate
                if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                    player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(1000)), completionHandler: { [weak self](success) in
                        guard let self = self else {return}
                        if success {
                            self.player?.rate = playerRate
                        }
                    })
                    return .success
                }
            }
            return .commandFailed
        }
 
 
        commandCenter.playCommand.addTarget { [unowned self] event in
                self.playerToggler()
                return .success
        }
        
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.playerToggler()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(self.skipPrevious(_:)))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(self.skipForward(_:)))
        
    }
    
    func setupNotificationView(currentChapter: String){
        nowPlayingInfo[MPMediaItemPropertyTitle] = book.Title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = currentChapter
        nowPlayingInfo[MPMediaItemPropertyArtist] = book.AuthorFirstName + " " + book.AuthorLastName
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = progressSlider.maximumValue
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func playAudioBook(url: URL){
        
        
        let playerItem: AVPlayerItem = AVPlayerItem(url: url)
        let seconds : Float64 = CMTimeGetSeconds(playerItem.asset.duration)
        
        if(seconds.isNaN){
            SVProgressHUD.show(withStatus: "Bandoma prisijungti prie serverio!..")
            SVProgressHUD.setDefaultMaskType(.black)
            let username = Utils.readFromSharedPreferences(key: "username") as! String
            let password = Utils.readFromSharedPreferences(key: "password") as! String
            let userID = Utils.readFromSharedPreferences(key: "userID") as! String
            let disabilities = Utils.readFromSharedPreferences(key: "haveDisabilities") as! String
            DatabaseUtils.GetCookie(username: username, password: password, disabilities: disabilities, userID: userID, onFinishLoginListener: { (success, sessionIDNew) in
                
                //Downloading books with the new sessionID
                guard success, let sessionIDNew = sessionIDNew else{
                    SVProgressHUD.show(withStatus: "Klaida serveryje!")
                    return
                }
                
                self.sessionID = sessionIDNew
                Utils.writeToSharedPreferences(key: "sessionID", value: sessionIDNew)
                SVProgressHUD.dismiss()
                

                let checkSeconds = self.getMusicLengthSeconds(url: self.createUrl())                
                guard !checkSeconds.isNaN else{
                    SVProgressHUD.showError(withStatus: "Klaida su failu serveryje!")
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                
                self.playAudioBook(url: self.createUrl())
            })
            
            return
        }
        
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = Float(seconds)
        
        //Probably no internet if it passed other checks
        if(progressSlider.maximumValue == 0){
            if(player != nil){
                player?.rate = 0
            }
            playButton.setImage(UIImage(named: "Groti"), for: .normal)
            SVProgressHUD.showError(withStatus: "Klaida!")
            return
        }
        
        
        playButton.setImage(UIImage(named: "Pauze"), for: .normal)
        player = AVPlayer(playerItem: playerItem)
        
        player?.automaticallyWaitsToMinimizeStalling = true
        
        player?.play()
        startPlayerControllerTimer()
        
        setupNotificationView(currentChapter: chapters[selectedChapterIndex])
        
    }
    
   
    
    
    func startPlayerControllerTimer(){
        timer =  Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        timerRunning = true;
    }
    
    func stopPlayerControllerTimer(){
        if timer != nil {
            timerRunning = false
            timer!.invalidate()
            timer = nil
        }
    }
    
    func configureAudioSession() {
        //Configuration for listening in background
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
           
        }catch{
            print(error)
        }

    }
    
    func playerIsPlaying() -> Bool{
        return player?.rate != 0
    }
    
    func getMusicLengthSeconds(url: URL) -> Float64{
        let checkItem: AVPlayerItem = AVPlayerItem(url: url)
        let checkSeconds : Float64 = CMTimeGetSeconds(checkItem.asset.duration)
        return checkSeconds
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
        progressSlider.isHidden = false
        progressSlider.setValue(0, animated: true)
        
        setNotificationPlayerTime(playBackRate: 1, elapsedTime: Float(CMTimeGetSeconds(CMTime.zero)))
        
        tv_time.text = "0:00"
        stopPlayerControllerTimer()
        
        playAudioBook(url: createUrl())
        view.endEditing(true)
    }
    
    @objc func timerAction(){
        if(timerRunning){
            let value = progressSlider.value
            if(value == progressSlider.maximumValue){
                skipForward.sendActions(for: .touchUpInside)
                return;
            }
            
            setNotificationPlayerTime(playBackRate: 1, elapsedTime: Float(CMTimeGetSeconds((player?.currentTime())!)))
            progressSlider.setValue(Float(CMTimeGetSeconds((player?.currentTime())!)), animated: true)
            
            tv_time.text = timeLabelSetter(seconds: Int(CMTimeGetSeconds((player?.currentTime())!)))
            tv_time.accessibilityValue = tv_time.text
        }
    }
 
    func setNotificationPlayerTime(playBackRate: Int, elapsedTime: Float){
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playBackRate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
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
        tv_bookTitle.accessibilityLabel = "Knygos pavadinimas"
        tv_bookTitle.accessibilityValue = book.Title
        
        chapterTextField.isAccessibilityElement = true
        chapterTextField.accessibilityTraits = UIAccessibilityTraits.button
        chapterTextField.accessibilityLabel = "Pasirinkite knygos skirsnį"
        chapterTextField.accessibilityValue = "Knygos skirsnių pasirinkimas atsiras ekrano apačioje"
        
        tv_time.isAccessibilityElement = true
        tv_time.accessibilityLabel = "Laikas"
        tv_time.accessibilityValue = tv_time.text
        
        progressSlider.isAccessibilityElement = true
        progressSlider.accessibilityLabel = "Laiko juosta"
        progressSlider.accessibilityValue = "Spauskite norėdami pakeisti esamą laiką"
        
    }
}
