//
//  BTRRootViewController.m
//  TankRemote
//
//  Created by Taylan Pince on 2013-10-14.
//  Copyright (c) 2013 Hipo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#import "BLE.h"
#import "SGSVideoPeer.h"

#import "BTRRootViewController.h"

#import "UIView+AutoLayout.h"


typedef enum {
    BTRMotorStatusNeutral,
    BTRMotorStatusForward,
    BTRMotorStatusBackward,
} BTRMotorStatus;

typedef enum {
    BTRMotorTypeLeft,
    BTRMotorTypeRight,
} BTRMotorType;


@interface BTRRootViewController () <BLEDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate, SGSVideoPeerDelegate>

@property (nonatomic, strong) BLE *bluetoothController;
@property (nonatomic, assign) BTRMotorStatus leftMotorStatus;
@property (nonatomic, assign) BTRMotorStatus rightMotorStatus;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;

@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UISlider *leftSlider;
@property (nonatomic, strong) UISlider *rightSlider;
@property (nonatomic, strong) UILabel *accelerometerStatusLabel;

@property (nonatomic, assign) NSInteger initialMotionUpdates;
@property (nonatomic, assign) double initialRoll;
@property (nonatomic, assign) double initialYaw;
@property (nonatomic, assign) double currentRoll;
@property (nonatomic, assign) double currentYaw;

@property (nonatomic, strong) MCPeerID *devicePeerIdentifier;
@property (nonatomic, strong) MCSession *cameraSession;
@property (nonatomic, strong) MCNearbyServiceBrowser *serviceBrowser;
@property (nonatomic, strong) SGSVideoPeer *activePeer;
@property (nonatomic, strong) UIImageView *cameraView;

- (void)didChangeLeftSliderValue:(id)sender;
- (void)didChangeRightSliderValue:(id)sender;
- (void)didDropLeftSlider:(id)sender;
- (void)didDropRightSlider:(id)sender;
- (void)didTapConnectButton:(id)sender;
- (void)didTapResetButton:(id)sender;
- (void)didTapMessageButton:(id)sender;

- (void)startMotionManager;
- (void)stopMotionManager;

- (void)convertSliderValue:(float)value
                  forMotor:(BTRMotorType)motor;

- (void)updateMotor:(BTRMotorType)motor
           toStatus:(BTRMotorStatus)status
          withPower:(CGFloat)power;

- (void)updateVerticalAngle:(CGFloat)verticalAngle
            horizontalAngle:(CGFloat)horizontalAngle;

@end


@implementation BTRRootViewController

- (id)init {
    self = [super init];

    if (self) {
        _bluetoothController = [[BLE alloc] init];
        
        [_bluetoothController controlSetup:1];
        [_bluetoothController setDelegate:self];
        
        _leftMotorStatus = BTRMotorStatusNeutral;
        _rightMotorStatus = BTRMotorStatusNeutral;
        
        _initialMotionUpdates = 0;
        _motionManager = [[CMMotionManager alloc] init];
        _motionQueue = [[NSOperationQueue alloc] init];
        
        [_motionManager setDeviceMotionUpdateInterval:1.0 / 10.0];
        
        _devicePeerIdentifier = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        _cameraSession = [[MCSession alloc] initWithPeer:_devicePeerIdentifier
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
        
        [_cameraSession setDelegate:self];
        
        _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_devicePeerIdentifier
                                                           serviceType:@"multipeer-video"];
        
        [_serviceBrowser setDelegate:self];
        [_serviceBrowser startBrowsingForPeers];
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _leftSlider = [[UISlider alloc] initForAutoLayout];
    _rightSlider = [[UISlider alloc] initForAutoLayout];
    
    [_leftSlider setMinimumValue:0.0];
    [_rightSlider setMinimumValue:0.0];
    [_leftSlider setMaximumValue:100.0];
    [_rightSlider setMaximumValue:100.0];
    [_leftSlider setValue:50.0 animated:NO];
    [_rightSlider setValue:50.0 animated:NO];
//    [_leftSlider setEnabled:[_bluetoothController isConnected]];
//    [_rightSlider setEnabled:[_bluetoothController isConnected]];
    [_leftSlider setTransform:CGAffineTransformMakeRotation(M_PI * -0.5)];
    [_rightSlider setTransform:CGAffineTransformMakeRotation(M_PI * -0.5)];
    [_leftSlider addTarget:self action:@selector(didDropLeftSlider:) forControlEvents:UIControlEventTouchUpInside];
    [_rightSlider addTarget:self action:@selector(didDropRightSlider:) forControlEvents:UIControlEventTouchUpInside];
    
    [_leftSlider addTarget:self
                   action:@selector(didChangeLeftSliderValue:)
         forControlEvents:UIControlEventValueChanged];
    
    [_rightSlider addTarget:self
                    action:@selector(didChangeRightSliderValue:)
          forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:_leftSlider];
    [self.view addSubview:_rightSlider];
    
    _connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [_connectButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    if ([_bluetoothController isConnected]) {
        [_connectButton setTitle:NSLocalizedString(@"Disconnect", nil) forState:UIControlStateNormal];
    } else {
        [_connectButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
    }
    
    [_connectButton addTarget:self
                       action:@selector(didTapConnectButton:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_connectButton];
    
    [_connectButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_leftSlider withOffset:10.0];
    [_connectButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20.0];
    [_connectButton autoSetDimensionsToSize:CGSizeMake(100.0, 44.0)];

    UIButton *messageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [messageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [messageButton addTarget:self action:@selector(didTapMessageButton:) forControlEvents:UIControlEventTouchUpInside];
    [messageButton setTitle:NSLocalizedString(@"Hello", nil) forState:UIControlStateNormal];
    
    [self.view addSubview:messageButton];
    
    [messageButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:_rightSlider withOffset:-10.0];
    [messageButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20.0];
    [messageButton autoSetDimensionsToSize:CGSizeMake(100.0, 44.0)];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [resetButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [resetButton addTarget:self action:@selector(didTapResetButton:) forControlEvents:UIControlEventTouchUpInside];
    [resetButton setTitle:NSLocalizedString(@"Reset", nil) forState:UIControlStateNormal];
    
    [self.view addSubview:resetButton];
    
    [resetButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_connectButton withOffset:10.0];
    [resetButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:messageButton withOffset:-10.0];
    [resetButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20.0];
    
    CGFloat offset = 20.0;
    
    [_leftSlider autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:offset];
    [_leftSlider autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:offset];
    [_leftSlider autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:offset];
    
    [_rightSlider autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:offset];
    [_rightSlider autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:offset];
    [_rightSlider autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:offset];
    
    _accelerometerStatusLabel = [[UILabel alloc] initForAutoLayout];
    
    [_accelerometerStatusLabel setBackgroundColor:[UIColor whiteColor]];
    [_accelerometerStatusLabel setFont:[UIFont systemFontOfSize:14.0]];
    [_accelerometerStatusLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.view addSubview:_accelerometerStatusLabel];
    
    [_accelerometerStatusLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20.0];
    [_accelerometerStatusLabel autoCenterInSuperviewAlongAxis:ALAxisVertical];
    [_accelerometerStatusLabel autoSetDimension:ALDimensionWidth toSize:250.0];
    
    _cameraView = [[UIImageView alloc] initForAutoLayout];
    
    [self.view addSubview:_cameraView];
    [self.view sendSubviewToBack:_cameraView];
    
    [_cameraView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

#pragma mark - Control actions

- (void)didTapConnectButton:(id)sender {
    [_connectButton setEnabled:NO];
    
    if ([_bluetoothController isConnected]) {
        // Disconnect
        [self updateVerticalAngle:90.0 horizontalAngle:90.0];
        [self stopMotionManager];

        [_bluetoothController.CM cancelPeripheralConnection:_bluetoothController.activePeripheral];
        
        [_connectButton setTitle:NSLocalizedString(@"Disconnecting...", nil) forState:UIControlStateNormal];
        [_connectButton setNeedsLayout];
        
        _initialMotionUpdates = 0;
    } else {
        // Connect
        [_bluetoothController setPeripherals:nil];
        [_bluetoothController findBLEPeripherals:5];
        
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ([_bluetoothController.peripherals count] > 0) {
                [_bluetoothController connectPeripheral:[_bluetoothController.peripherals objectAtIndex:0]];
            } else {
                [_connectButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
                [_connectButton setEnabled:YES];
                [_connectButton setNeedsLayout];
            }
        });
        
        [_connectButton setTitle:NSLocalizedString(@"Connecting...", nil) forState:UIControlStateNormal];
        [_connectButton setNeedsLayout];
    }
}

- (void)didTapMessageButton:(id)sender {
    if (_activePeer == nil || _activePeer.peerID == nil) {
        return;
    }
    
    NSData* data = [@"msg:--:HELLO!" dataUsingEncoding:NSUTF8StringEncoding];
    [_cameraSession sendData:data toPeers:@[_activePeer.peerID] withMode:MCSessionSendDataReliable error:nil];
}

- (void)didTapResetButton:(id)sender {
    if (![_bluetoothController isConnected]) {
        return;
    }

    if (_initialMotionUpdates < 10) {
        return;
    }
    
    [self stopMotionManager];
    [self startMotionManager];
}

- (void)didChangeLeftSliderValue:(id)sender {
//    NSLog(@"Left: %1.2f", _leftSlider.value);
    
    [self convertSliderValue:_leftSlider.value forMotor:BTRMotorTypeLeft];
}

- (void)didChangeRightSliderValue:(id)sender {
//    NSLog(@"Right: %1.2f", _rightSlider.value);

    [self convertSliderValue:_rightSlider.value forMotor:BTRMotorTypeRight];
}

- (void)didDropLeftSlider:(id)sender {
//    NSLog(@">>> DROP LEFT");
    
    [_leftSlider setValue:50.0 animated:YES];

    [self convertSliderValue:50.0 forMotor:BTRMotorTypeLeft];
}

- (void)didDropRightSlider:(id)sender {
//    NSLog(@">>> DROP RIGHT");
    
    [_rightSlider setValue:50.0 animated:YES];

    [self convertSliderValue:50.0 forMotor:BTRMotorTypeRight];
}

#pragma mark - Motion manager

- (void)stopMotionManager {
    [_motionManager stopDeviceMotionUpdates];
}

- (void)startMotionManager {
    _initialYaw = 0.0;
    _initialRoll = 0.0;
    _initialMotionUpdates = 0;
    
    [_motionManager
     startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXMagneticNorthZVertical
     toQueue:_motionQueue
     withHandler:^(CMDeviceMotion *motion, NSError *error) {
         if (_initialMotionUpdates < 10) {
             _initialMotionUpdates += 1;
             _initialRoll += motion.attitude.roll;
             _initialYaw += motion.attitude.yaw;
             
             if (_initialMotionUpdates == 10) {
                 _initialRoll /= 10.0;
                 _initialYaw /= 10.0;
             }
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [_accelerometerStatusLabel setText:[NSString stringWithFormat:@"Warming Up: %d%%",
                                                     _initialMotionUpdates * 10]];
             });
             
             return;
         }
         
         _currentRoll = _initialRoll - motion.attitude.roll;
         _currentYaw = _initialYaw - motion.attitude.yaw;
         
         CGFloat verticalAngle = 180.0 * (fmax(fmin(_currentRoll + 1.0, 2.0), 0.0) / 2.0);
         CGFloat horizontalAngle = 180.0 - (180.0 * (fmax(fmin(_currentYaw + 1.0, 2.0), 0.0) / 2.0));
         
         [self updateVerticalAngle:verticalAngle horizontalAngle:horizontalAngle];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [_accelerometerStatusLabel setText:[NSString stringWithFormat:@"Roll: %1.2f / Yaw: %1.2f",
                                                 _currentRoll, _currentYaw]];
         });
     }];
}

#pragma mark - Bluetooth LE delegate

- (void)bleDidConnect {
    [_connectButton setTitle:NSLocalizedString(@"Disconnect", nil) forState:UIControlStateNormal];
    [_connectButton setEnabled:YES];
    [_leftSlider setEnabled:YES];
    [_rightSlider setEnabled:YES];
    
    [self startMotionManager];
}

- (void)bleDidDisconnect {
    [_connectButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
    [_connectButton setEnabled:YES];
    [_leftSlider setEnabled:NO];
    [_rightSlider setEnabled:NO];
    
    [self stopMotionManager];
}

- (void)bleDidReceiveData:(unsigned char *)data length:(int)length {
    
}

- (void)bleDidUpdateRSSI:(NSNumber *)rssi {
    
}

#pragma mark - Motor updates

- (void)convertSliderValue:(float)value
                  forMotor:(BTRMotorType)motor {
    
    BTRMotorStatus newStatus = BTRMotorStatusNeutral;
    CGFloat power = 0.0;
    
    if (value > 50.0) {
        newStatus = BTRMotorStatusForward;
        power = 255.0 / 50.0 * (value - 50.0);
    } else if (value < 50.0) {
        newStatus = BTRMotorStatusBackward;
        power = 255.0 / 50.0 * (50.0 - value);
    }
    
    power = floorf(power);
    
    [self updateMotor:motor
             toStatus:newStatus
            withPower:power];
}

- (void)updateMotor:(BTRMotorType)motor
           toStatus:(BTRMotorStatus)status
          withPower:(CGFloat)power {
    
    if (![_bluetoothController isConnected]) {
        return;
    }
    
    BTRMotorStatus oldStatus = BTRMotorStatusNeutral;
    
    switch (motor) {
        case BTRMotorTypeRight:
            oldStatus = _rightMotorStatus;
            break;
        case BTRMotorTypeLeft:
            oldStatus = _leftMotorStatus;
            break;
    }
    
    if (status != oldStatus) {
        // Update motor status

        UInt8 statusBuffer[3] = {0x00, 0x00, 0x00};
        
        switch (motor) {
            case BTRMotorTypeRight: {
                _rightMotorStatus = status;
                statusBuffer[0] = 0x01;
                NSLog(@"RIGHT MOTOR: %d", status);
                break;
            }
            case BTRMotorTypeLeft: {
                _leftMotorStatus = status;
                statusBuffer[0] = 0x03;
                NSLog(@"LEFT MOTOR: %d", status);
                break;
            }
        }
        
        switch (status) {
            case BTRMotorStatusBackward:
                statusBuffer[1] = 0x00;
                break;
            case BTRMotorStatusForward:
                statusBuffer[1] = 0x01;
                break;
            default:
                break;
        }
        
        NSData *statusData = [[NSData alloc] initWithBytes:statusBuffer length:3];
        
        [_bluetoothController write:statusData];
    }
    
    UInt8 powerBuffer[3] = {0x00, 0x00, 0x00};
    
    // Update motor power
    switch (motor) {
        case BTRMotorTypeRight: {
            NSLog(@"RIGHT MOTOR: %f", power);
            powerBuffer[0] = 0x02;
            break;
        }
        case BTRMotorTypeLeft: {
            NSLog(@"LEFT MOTOR: %f", power);
            powerBuffer[0] = 0x04;
            break;
        }
    }
    
    powerBuffer[1] = power;
    powerBuffer[2] = (int)power >> 8;

    NSData *powerData = [[NSData alloc] initWithBytes:powerBuffer length:3];
    
    [_bluetoothController write:powerData];
}

- (void)updateVerticalAngle:(CGFloat)verticalAngle
            horizontalAngle:(CGFloat)horizontalAngle {
    
    if (![_bluetoothController isConnected]) {
        return;
    }
    NSLog(@"%1.2f / %1.2f", verticalAngle, horizontalAngle);
    UInt8 angleBuffer[3] = {0x05, 0x00, 0x00};
    
    angleBuffer[1] = floorf(verticalAngle);
    angleBuffer[2] = floorf(horizontalAngle);
    
    NSData *angleData = [[NSData alloc] initWithBytes:angleBuffer length:3];
    
    [_bluetoothController write:angleData];
}

#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
	switch (state) {
		case MCSessionStateConnected: {
            NSLog(@"PEER CONNECTED: %@", peerID.displayName);
            dispatch_async(dispatch_get_main_queue(), ^{
                SGSVideoPeer *newVideoPeer = [[SGSVideoPeer alloc] initWithPeer:peerID];

                newVideoPeer.delegate = self;
                
                _activePeer = newVideoPeer;
            });
            
			break;
        }
		case MCSessionStateConnecting:
            NSLog(@"PEER CONNECTING: %@", peerID.displayName);
			break;
		case MCSessionStateNotConnected: {
            NSLog(@"PEER NOT CONNECTED: %@", peerID.displayName);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [_activePeer stopPlaying];
                _activePeer = nil;
            });
			break;
        }
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    //    NSLog(@"(%@) Read %d bytes", peerID.displayName, data.length);
    NSDictionary* dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    CIImage *sourceImage = [CIImage imageWithData:[dict objectForKey:@"image"]];
    UIImage* image = [UIImage imageWithCIImage:sourceImage scale:2.0 orientation:UIImageOrientationDown];
    NSNumber* framesPerSecond = dict[@"framesPerSecond"];

    [_activePeer addImageFrame:image withFPS:framesPerSecond];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void) browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    
}

- (void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    [browser invitePeer:peerID toSession:_cameraSession withContext:nil timeout:0];
}

- (void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    
}

#pragma mark - SGSVideoPeerDelegate

- (void) showImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_cameraView setImage:image];
    });
}

- (void) raiseFramerateForPeer:(MCPeerID *)peerID {
    NSLog(@"(%@) raise framerate", peerID.displayName);
    NSData* data = [@"raiseFramerate" dataUsingEncoding:NSUTF8StringEncoding];
    [_cameraSession sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}

- (void) lowerFramerateForPeer:(MCPeerID *)peerID {
    NSLog(@"(%@) lower framerate", peerID.displayName);
    NSData* data = [@"lowerFramerate" dataUsingEncoding:NSUTF8StringEncoding];
    [_cameraSession sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}

@end
