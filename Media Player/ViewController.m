//
//  ViewController.m
//  Media Player
//
//  Created by Justin Haar on 1/24/17.
//
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Constants.h"

@interface ViewController ()

@property (nonatomic, strong) AVQueuePlayer *player;
@property (weak, nonatomic) IBOutlet UILabel *labelStart;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *labelEnd;
@property (weak, nonatomic) IBOutlet UIButton *buttonGoBack;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlayPause;
@property (weak, nonatomic) IBOutlet UIButton *buttonNextSong;
@property (weak, nonatomic) IBOutlet UIButton *buttonChangeOutput;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barbuttonAdd;
@property (weak, nonatomic) IBOutlet UIButton *buttonChangeSong;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewLogo;
@property (nonatomic, strong) MPVolumeView *volumeView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.player = [AVQueuePlayer queuePlayerWithItems:@[[[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:kFadedUrl]]]];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
    [self addTimeObserverForLabelsAndSlider];
    
    [self setUpUI];
    [self configureAVAudioSession];
}

-(void)setUpUI
{
    //NAVIGATION BAR
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = @"Sky Player";
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName : [UIFont boldSystemFontOfSize:22]}];
    
    //PLAY PAUSE BUTTON
    [self.buttonPlayPause setImage:[UIImage imageNamed:@"Play Filled-50"] forState:UIControlStateNormal];
    [self.buttonPlayPause setImage:[UIImage imageNamed:@"Pause-48"] forState:UIControlStateSelected];
    [self.buttonPlayPause setSelected:NO];
    [self.buttonPlayPause addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
    
    self.labelStart.text = @"0:00";
    self.labelEnd.text = @"0:00";
    
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 1;
    self.slider.value = 0;
    [self.slider addTarget:self action:@selector(seekSong:) forControlEvents:UIControlEventValueChanged];
    
    
    [self.buttonGoBack addTarget:self action:@selector(startFromBeginning) forControlEvents:UIControlEventTouchUpInside];
    
    [self.buttonNextSong addTarget:self action:@selector(goToNextSong) forControlEvents:UIControlEventTouchUpInside];
        
    [self.buttonChangeSong addTarget:self action:@selector(getSongList) forControlEvents:UIControlEventTouchUpInside];
 
    UIView *volumeContainer = [[UIView alloc]initWithFrame:CGRectMake(0, self.buttonPlayPause.frame.origin.y - 50, self.slider.frame.size.width, 50)];
    [self.view addSubview:volumeContainer];
    self.volumeView = [[MPVolumeView alloc]initWithFrame:volumeContainer.bounds];
    self.volumeView.tintColor = [UIColor whiteColor];
    [volumeContainer addSubview:self.volumeView];
    volumeContainer.center = CGPointMake(self.view.center.x, volumeContainer.center.y);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachedEndOfSong:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

}

-(void)addTimeObserverForLabelsAndSlider
{
    __weak typeof(self) weakSelf = self;

    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CMTime endTime = CMTimeConvertScale (weakSelf.player.currentItem.asset.duration, weakSelf.player.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
        if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
            double normalizedTime = (double) self.player.currentTime.value / (double) endTime.value;
            weakSelf.slider.value = normalizedTime;
        }
        Float64 currentSeconds = CMTimeGetSeconds(weakSelf.player.currentTime);
        int mins = currentSeconds/60.0;
        int secs = fmodf(currentSeconds, 60.0);
        
        Float64 totalSeconds = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        int lastMin = (totalSeconds - currentSeconds) / 60;
        int lastSeconds = fmod(totalSeconds - currentSeconds, 60);
        
        NSString *minsString = mins < 10 ? [NSString stringWithFormat:@"0%d", mins] : [NSString stringWithFormat:@"%d", mins];
        NSString *secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
        
        NSString *lastMinString = lastMin < 10 ? [NSString stringWithFormat:@"0%d", lastMin] : [NSString stringWithFormat:@"%d", lastMin];
        NSString *lastSecString = lastSeconds < 10 ? [NSString stringWithFormat:@"0%d", lastSeconds] : [NSString stringWithFormat:@"%d", lastSeconds];
        
        weakSelf.labelStart.text = [NSString stringWithFormat:@"%@:%@", minsString, secsString];
        weakSelf.labelEnd.text = [NSString stringWithFormat:@"%@:%@",lastMinString, lastSecString];
    }];
}

- (void)configureAVAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    // Error handling
    BOOL success;
    NSError *error;
    
    // set the audioSession category.
    // Needs to be Record or PlayAndRecord to use audioRouteOverride:
    
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    
    if (!success) {
        NSLog(@"AVAudioSession error setting category:%@",error);
    }
    
    // Set the audioSession override
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                         error:&error];
    if (!success) {
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    }
    
    // Activate the audio session
    success = [session setActive:YES error:&error];
    if (!success) {
        NSLog(@"AVAudioSession error activating: %@",error);
    }
    else {
        NSLog(@"AudioSession active");
    }
    
}

#pragma mark -NOTIFICATIONS
-(void)reachedEndOfSong:(NSNotification*)notification
{
    [self goToNextSong];
}

#pragma mark -BUTTON METHODS

-(void)startFromBeginning
{
    CMTime time = CMTimeSubtract(self.player.currentTime, self.player.currentTime);

    [self.player seekToTime:time];
}

-(void)playPause:(UIButton*)button
{
    button.selected = !button.selected;
    if (button.selected) {
        [self.player play];
    }else
    {
        [self.player pause];
    }
}

-(void)goToNextSong
{
    BOOL isEmpty = self.player.currentItem == self.player.items.lastObject;
    if (isEmpty) {
        [self showAlertWithTitle:@"No Songs" andMessage:@"There are no more songs in the queue" withTextField:NO andStyle:UIAlertControllerStyleAlert withSongs:nil];
    }else
    {
        [self.player advanceToNextItem];
        NSString *reason = self.player.reasonForWaitingToPlay;
        if (reason) {
            [self showAlertWithTitle:@"Error" andMessage:reason withTextField:NO andStyle:UIAlertControllerStyleAlert withSongs:nil];
        }
    }
}

-(void)seekSong:(UISlider*)slider
{
    CMTime t = CMTimeMake(slider.value * self.player.currentItem.duration.value, self.player.currentItem.duration.timescale);
    [self.player seekToTime:t];
}


- (IBAction)addSong:(UIBarButtonItem *)sender {
    
    [self showAlertWithTitle:@"Add Song" andMessage:@"Enter the URL for a song." withTextField:YES andStyle:UIAlertControllerStyleAlert withSongs:nil];
    
}

-(void)getSongList
{
    [self showAlertWithTitle:@"Song List" andMessage:@"Choose a song to play." withTextField:NO andStyle:UIAlertControllerStyleActionSheet withSongs:self.player.items];
}

#pragma mark -ALERT METHODS

-(void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)message
{
    [self showAlertWithTitle:title andMessage:message withSongs:nil];
}

-(void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)message withSongs:(NSArray*)songs
{
    [self showAlertWithTitle:title andMessage:message withTextField:NO andStyle:UIAlertControllerStyleActionSheet withSongs:songs];
}

-(void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)message withTextField:(BOOL)showTextField andStyle:(NSInteger)style withSongs:(NSArray*)songs
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:style];
    
    //get song list
    if (songs){
        for (AVPlayerItem *item in songs) {
            AVURLAsset *asset = (AVURLAsset*)item.asset;
            
            UIAlertAction *playSong = [UIAlertAction actionWithTitle:asset.URL.lastPathComponent style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    if (item != self.player.currentItem) {
                        [self.player insertItem:item afterItem:self.player.currentItem];
                        [self.player advanceToNextItem];
                    }else
                    {
                        [self startFromBeginning];
                    }
                
            }];
            
            [alert addAction:playSong];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    //add new song
    if (showTextField) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Enter URL";
            textField.text = kFadedUrl;
        }];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Add Song" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *songURL = alert.textFields[0].text;
            
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:songURL]];
            
            [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^{
                AVPlayerItem *newItem = [[AVPlayerItem alloc]initWithAsset:asset];
                if (newItem) {
                     
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.player insertItem:newItem afterItem:self.player.items.lastObject];
                        [self.player play];
                        
                    });
                }
            }];
            
        }];
        
        [alert addAction:action];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
        
    }else
    {
        //error no songs left
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

@end
