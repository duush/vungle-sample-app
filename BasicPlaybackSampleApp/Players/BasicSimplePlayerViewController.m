/**
 * @class      BasicSimplePlayerViewController BasicSimplePlayerViewController.m "BasicSimplePlayerViewController.m"
 * @brief      A Player that can be used to simply load an embed code and play it
 * @details    BasicSimplePlayerViewController in Ooyala Sample Apps
 * @date       01/12/15
 * @copyright  Copyright (c) 2015 Ooyala, Inc. All rights reserved.
 */

#import "BasicSimplePlayerViewController.h"
#import <OoyalaSDK/OoyalaSDK.h>
#import "AppDelegate.h"
#import <VungleSDK/VungleSDK.h>

//static VungleSDK *sdk;
static NSString *vungleAppId = @"58fe200484fbd5b9670000e3";
static NSString *vunglePlacementId01 = @"DEFAULT87043";
static NSString *vunglePlacementId02 = @"PLMT03R77999";

//static NSArray *placementIDsArray;
BOOL *initialized;

@interface BasicSimplePlayerViewController ()

#pragma mark - Private properties

@property (strong, nonatomic) OOOoyalaPlayerViewController *ooyalaPlayerViewController;
@property (nonatomic) NSString *embedCode;
@property (nonatomic) NSString *nib;
@property (nonatomic) NSString *pcode;
@property (nonatomic) NSString *playerDomain;
@property (nonatomic) NSString *placement;


@property (nonatomic, strong) VungleSDK *sdk;
@property (nonatomic, strong) NSArray *placementIDsArray;

@end


@implementation BasicSimplePlayerViewController {
    AppDelegate *appDel;
}

#pragma mark - Initialization

- (id)initWithPlayerSelectionOption:(PlayerSelectionOption *)playerSelectionOption qaModeEnabled:(BOOL)qaModeEnabled {
  self = [super initWithPlayerSelectionOption: playerSelectionOption qaModeEnabled:qaModeEnabled];
  self.nib = @"PlayerSimple";
  NSLog(@"value of qa mode in BasicSimplePlayerviewController %@", self.qaModeEnabled ? @"YES" : @"NO");
  if (self.playerSelectionOption) {
    self.embedCode = self.playerSelectionOption.embedCode;
    self.title = self.playerSelectionOption.title;
    self.pcode = self.playerSelectionOption.pcode;
    self.playerDomain = self.playerSelectionOption.domain;
    self.placement = self.playerSelectionOption.placement;
  } else {
    NSLog(@"There was no PlayerSelectionOption!");
    return nil;
  }
  return self;
}

#pragma mark - Life cycle

- (void)loadView {
  [super loadView];
  [[NSBundle mainBundle] loadNibNamed:self.nib owner:self options:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
    //initialize vungle
  NSError *error = nil;
  [self initializeVungle];
    
    
  appDel = (AppDelegate *)UIApplication.sharedApplication.delegate;
  
  // Create Ooyala ViewController
  OOOoyalaPlayer *player = [[OOOoyalaPlayer alloc] initWithPcode:self.pcode
                                                          domain:[[OOPlayerDomain alloc] initWithString:self.playerDomain]];
  
  self.ooyalaPlayerViewController = [[OOOoyalaPlayerViewController alloc] initWithPlayer:player];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(notificationHandler:)
                                               name:nil
                                             object:self.ooyalaPlayerViewController.player];
  
  // In QA Mode , making textView visible
  if (self.qaModeEnabled == YES) {
    self.textView.hidden = NO;
  }
  
  // Attach it to current view
  [self addPlayerViewController:self.ooyalaPlayerViewController];
    
  // Load the video
  [self.ooyalaPlayerViewController.player setEmbedCode:self.embedCode];
  [self.ooyalaPlayerViewController.player play];
}

#pragma mark - Private functions

- (void)addPlayerViewController:(UIViewController *)playerViewController {
  playerViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self addChildViewController:playerViewController];
  [self.playerView addSubview:playerViewController.view];

  // Add constraints
  
  [NSLayoutConstraint activateConstraints:@[
                                            [playerViewController.view.topAnchor constraintEqualToAnchor:self.playerView.topAnchor],
                                            [playerViewController.view.leadingAnchor constraintEqualToAnchor:self.playerView.leadingAnchor],
                                            [playerViewController.view.bottomAnchor constraintEqualToAnchor:self.playerView.bottomAnchor],
                                            [playerViewController.view.trailingAnchor constraintEqualToAnchor:self.playerView.trailingAnchor]
                                            ]];
}

#pragma mark - Actions

- (void) notificationHandler:(NSNotification*) notification {
  
  // Ignore TimeChangedNotificiations for shorter logs
  if ([notification.name isEqualToString:OOOoyalaPlayerTimeChangedNotification]) {
    return;
  }
    
    if ([notification.name isEqualToString:OOOoyalaPlayerPlayStartedNotification]) {
        NSLog(@"=====Loading Ad=====");
        [self loadVungleAd];
    }
    
    
    if ([notification.name isEqualToString:OOOoyalaPlayerPlayCompletedNotification]) {
        NSLog(@"===Calling Play Ad===");
        [self playVungleAd];
    }
  
  NSString *message = [NSString stringWithFormat:@"Notification Received: %@. state: %@. playhead: %f count: %d",
                       [notification name],
                       [OOOoyalaPlayer playerStateToString:[self.ooyalaPlayerViewController.player state]],
                       [self.ooyalaPlayerViewController.player playheadTime], appDel.count];
  
  NSLog(@"%@",message);
// if(message == )
  
  // In QA Mode , adding notifications to the TextView
  if (self.qaModeEnabled == YES) {
    NSString *string = self.textView.text;
    NSString *appendString = [NSString stringWithFormat:@"%@ :::::::::: %@", string, message];
    [self.textView setText:appendString];
  }
  
  appDel.count++;
}

- (void)vungleSDKDidInitialize {
    NSError *error = nil;
    NSLog(@"-->> Delegate Callback: vungleSDKDidInitialize - SDK initialized SUCCESSFULLY");
}

- (void)initializeVungle {
    NSError *error = nil;
    self.sdk = [VungleSDK sharedSDK];
    [self.sdk setDelegate:self];
    [self.sdk setLoggingEnabled:YES];
    self.placementIDsArray = [NSArray arrayWithObjects:vunglePlacementId01,vunglePlacementId02, nil];
    if(![self.sdk startWithAppId:vungleAppId placements:self.placementIDsArray error:&error]) {
        NSLog(@"Error while starting VungleSDK %@", [error localizedDescription]);
        return;
    }
}

- (void) playVungleAd{
    NSError *error = nil;
    [self.sdk playAd:self options:nil placementID:self.placement error:&error];
    if (error) {
        NSLog(@"Error encountered playing ad: %@", error);
    }
}


- (void) loadVungleAd{
    NSError *error = nil;
    [self.sdk  loadPlacementWithID:self.placement  error:&error];
    if (error) {
        NSLog(@"Error encountered loading ad: %@", error);
    }
}


@end
