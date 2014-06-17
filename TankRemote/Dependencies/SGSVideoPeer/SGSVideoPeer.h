//
//  SGSVideoPeer.h
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 1/1/14.
//  Copyright (c) 2014 Say Goodnight Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol SGSVideoPeerDelegate <NSObject>
- (void) showImage:(UIImage*) image;
- (void) raiseFramerateForPeer:(MCPeerID*) peerID;
- (void) lowerFramerateForPeer:(MCPeerID*) peerID;
@end

@interface SGSVideoPeer : NSObject

@property (nonatomic, strong, readonly) MCPeerID *peerID;
@property (strong, nonatomic) id delegate;
@property BOOL useAutoFramerate;

- (instancetype) initWithPeer:(MCPeerID*) peerID;

- (void) addImageFrame:(UIImage*) image withFPS:(NSNumber*) fps;
- (void) stopPlaying;

@end
