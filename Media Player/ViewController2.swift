//
//  ViewController2.swift
//  Media Player
//
//  Created by Justin Haar on 2/11/17.
//
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer

class ViewController2: UIViewController {
    
    @IBOutlet weak var labelStart: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var labelEnd: UILabel!
    @IBOutlet weak var buttonGoBack: UIButton!
    @IBOutlet weak var buttonPlayPause: UIButton!
    @IBOutlet weak var buttonNextSong: UIButton!
    @IBOutlet weak var barbuttonAdd: UIBarButtonItem!
    @IBOutlet weak var buttonChangeSong: UIButton!
    @IBOutlet weak var imageViewLogo: UIImageView!
    
    private var volumeView: MPVolumeView!
    private var player:AVQueuePlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVQueuePlayer.init(items: [AVPlayerItem.init(url: URL.init(string: kFadedUrl)!)])
        self.player.actionAtItemEnd = AVPlayerActionAtItemEnd.advance
        
        self.addTimeObserverForLabelsAndSlider()
        
        self.setUpUI()
        
        self.configureAVAudioSession()
        
    }
    
    //MARK: -SETUP METHODS

    func setUpUI() -> Void
    {
        //NAVIGATION BAR
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationItem.title = "Sky Player"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white , NSFontAttributeName : UIFont.boldSystemFont(ofSize: 22)]
        
        //PLAY PAUSE BUTTON
        self.buttonPlayPause.setImage(#imageLiteral(resourceName: "Play Filled-50.png"), for: UIControlState.normal)
        self.buttonPlayPause.setImage(#imageLiteral(resourceName: "Pause-48.png"), for: UIControlState.selected)
        self.buttonPlayPause.addTarget(self, action:#selector(playPause(_:)), for: UIControlEvents.touchUpInside)
        
        self.labelStart.text = "0:00"
        self.labelEnd.text = "0:00"
        
        self.slider.minimumValue = 0
        self.slider.maximumValue = 1
        self.slider.value = 0
        self.slider.addTarget(self, action:#selector(seekSong(_:)) , for: UIControlEvents.valueChanged)
        self.slider.addTarget(self, action: #selector(addTimeObserverForLabelsAndSlider), for: UIControlEvents.touchUpOutside)
        
        self.buttonGoBack.addTarget(self, action:#selector(startFromBeginning), for: UIControlEvents.touchUpInside)
        
        self.buttonNextSong.addTarget(self, action:#selector(goToNextSong), for: UIControlEvents.touchUpInside)
        
        self.buttonChangeSong.addTarget(self, action:#selector(getSongList), for: UIControlEvents.touchUpInside)
        
        self.volumeView = MPVolumeView.init(frame: CGRect.init(x: 20, y: self.buttonPlayPause.frame.origin.y - 50, width: self.view.frame.size.width * 0.75, height: 50))
        self.volumeView.center = CGPoint.init(x: self.buttonPlayPause.center.x, y: self.volumeView.center.y)
        self.volumeView.tintColor = UIColor.white
        self.view.addSubview(self.volumeView)
        
        NotificationCenter.default.addObserver(self, selector:#selector(reachedEndOfSong), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func addTimeObserverForLabelsAndSlider() -> Void
    {
        self.player.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1, preferredTimescale: 1), queue: nil) { (time) in
            
            let endTime = CMTimeConvertScale((self.player.currentItem?.asset.duration)!, self.player.currentTime().timescale, CMTimeRoundingMethod.roundHalfAwayFromZero)
            let compare = CMTimeCompare(endTime, kCMTimeZero)

            if compare != 0
            {
               let normalizedTime = Float(self.player.currentTime().value) / Float(endTime.value)
                self.slider.value = normalizedTime
            }

            let startTuple = self.secondsToMinutesSeconds(seconds: Int(CMTimeGetSeconds(time)))
            
            let endTuple = self.secondsToMinutesSeconds(seconds: Int(CMTimeGetSeconds(CMTimeSubtract(endTime, time))))
            
            print("time is \(startTuple) time remainiing \(endTuple)")
            
            self.labelStart.text = String.init(format: "%d:%02d", startTuple.0, startTuple.1)
            self.labelEnd.text = String.init(format: "%d:%02d", endTuple.0, endTuple.1)
        }
    }
    
    func secondsToMinutesSeconds (seconds : Int) -> (Int, Int) {
        return ((seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func configureAVAudioSession() -> Void
    {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            print("AVAudioSession error setting category:%@",error)
        }
        
        do {
            try session.overrideOutputAudioPort(AVAudioSessionPortOverride.none)
        } catch {
            print("AVAudioSession error overrideOutputAudioPort:%@",error)
        }
        
        do {
            try session.setActive(true)
            print("AudioSession Active")
        } catch {
            print("AVAudioSession error activating: %@",error)
        }
        
    }
    
    //MARK: -TARGET METHODS
    func playPause(_ button:UIButton) -> Void
    {
        button.isSelected = !button.isSelected
        if button.isSelected
        {
            self.player.play()
        }else
        {
            self.player.pause()
        }
    }
    
    func seekSong(_ slider:UISlider) -> Void
    {
        let value = CGFloat(slider.value)
        let duration = CGFloat((self.player.currentItem?.duration.value)!)
        let time = CMTimeMake(Int64(value * duration), (self.player.currentItem?.duration.timescale)!)
        self.player.seek(to: time)
    }
    
    func startFromBeginning() -> Void
    {
        let time = CMTimeSubtract(self.player.currentTime(), self.player.currentTime())
        self.player .seek(to: time)
    }
    
    func goToNextSong() -> Void
    {
        let isEmpty = self.player.currentItem == self.player.items().last
        
        if isEmpty
        {
            self.showAlertWithTitle(title: "No Songs", message: "There are no more songs in the queue", showTextField: false, style: UIAlertControllerStyle.alert, songs: [])
        }else
        {
            self.player.advanceToNextItem()
            let reason = self.player.reasonForWaitingToPlay
            if (reason != nil)
            {
                self.showAlertWithTitle(title: "Error", message:reason!, showTextField: false, style: UIAlertControllerStyle.alert, songs: [])
            }
        }
    }
    
    @IBAction func addSong(_ sender: UIBarButtonItem)
    {
        self.showAlertWithTitle(title: "Add Song", message: "Enter the URL for the Song", showTextField: true, style: UIAlertControllerStyle.alert, songs: [])
    }
    
    func getSongList() -> Void
    {
        self.showAlertWithTitle(title: "Song List", message: "Choose a song to play.", showTextField: false, style: UIAlertControllerStyle.actionSheet, songs: self.player.items())
    }
    
    func reachedEndOfSong() -> Void
    {
        self.goToNextSong()
    }
    
    //MARK: -ALERT METHODS
    func showAlertWithTitle(title:String, message:String) -> Void
    {
        self.showAlertWithTitle(title: title, message: message, songs:[])
    }
    
    func showAlertWithTitle(title:String, message:String, songs:[AVPlayerItem]) -> Void
    {
        self.showAlertWithTitle(title: title, message: message, showTextField: false, style: UIAlertControllerStyle.actionSheet, songs: songs)
    }
    
    func showAlertWithTitle(title:String, message:String, showTextField:Bool, style:UIAlertControllerStyle, songs:[AVPlayerItem]) -> Void
    {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: style)
        
        if !songs.isEmpty
        {
            for item in songs {
                let asset = item.asset as! AVURLAsset
                let alertAction = UIAlertAction.init(title: asset.url.lastPathComponent, style: UIAlertActionStyle.default, handler: { (action) in
                    if item != self.player.currentItem
                    {
                        self.player.insert(item, after: self.player.currentItem)
                        self.player.advanceToNextItem()
                    }else
                    {
                        self.startFromBeginning()
                    }
                })
                
                alert.addAction(alertAction)
                
            }
            
            let cancel = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if showTextField
        {
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Enter URL"
                textField.text = kFadedUrl
            })
            
            let action = UIAlertAction.init(title: "Add Song", style: UIAlertActionStyle.default, handler: { (action) in
                
                let songURL = alert.textFields?[0].text
                let asset = AVURLAsset.init(url: URL.init(string: songURL!)!)
                
                asset.loadValuesAsynchronously(forKeys: ["playable"], completionHandler: { 
                    
                    let newItem = AVPlayerItem.init(asset: asset) as AVPlayerItem?
                        
                    if (newItem != nil)
                    {
                        DispatchQueue.main.async {
                            self.player.insert(newItem!, after: self.player.items().last)
                        }
                    }
                })
            })
            
            alert.addAction(action)
            
            let cancel = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
            
            
        }else
        {
            //error no song left
            let ok = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(ok)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
