//
//  TCMRootViewController.m
//  TankCamera
//
//  Created by Taylan Pince on 2014-06-13.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AVCaptureMultipeerVideoDataOutput.h"

#import "TCMRootViewController.h"


static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};


@interface TCMRootViewController () <AVCaptureMultipeerVideoDataOutputDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
//@property (nonatomic, strong) CIDetector *faceDetector;
//@property (nonatomic, strong) AVCaptureVideoDataOutput *faceDetectionOutput;
//@property (nonatomic, strong) dispatch_queue_t faceProcessingQueue;
//@property (nonatomic, strong) UIImage *borderImage;

//- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity
//                          frameSize:(CGSize)frameSize
//                       apertureSize:(CGSize)apertureSize;
//
//- (void)drawFaces:(NSArray *)features
//      forVideoBox:(CGRect)videoBox
//      orientation:(UIDeviceOrientation)orientation;
//
//- (NSNumber *)exifOrientation:(UIDeviceOrientation) orientation;

@end


@implementation TCMRootViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AVCaptureDevice *cameraDevice = nil;
    
    for (AVCaptureDevice *captureDevice in [AVCaptureDevice devices]) {
        if ([captureDevice hasMediaType:AVMediaTypeVideo] && [captureDevice position] == AVCaptureDevicePositionFront) {
            cameraDevice = captureDevice;
            break;
        }
    }
    
    if (cameraDevice) {
        [cameraDevice lockForConfiguration:nil];
        [cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 2)];
        [cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 2)];
        [cameraDevice unlockForConfiguration];
        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:nil];

        [self.captureSession addInput:videoDeviceInput];
        
        AVCaptureMultipeerVideoDataOutput *multipeerVideoOutput = [[AVCaptureMultipeerVideoDataOutput alloc]
                                                                   initWithDisplayName:[[UIDevice currentDevice] name]];

        [multipeerVideoOutput setDelegate:self];
        
        [self.captureSession addOutput:multipeerVideoOutput];
        
//        _borderImage = [UIImage imageNamed:@"border.png"];
//
//        NSDictionary *detectorOptions = @{CIDetectorAccuracyLow: CIDetectorAccuracy};
//        
//        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
//        _faceDetectionOutput = [[AVCaptureVideoDataOutput alloc] init];
//        
//        [_faceDetectionOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCMPixelFormat_32BGRA)}];
//        [_faceDetectionOutput setAlwaysDiscardsLateVideoFrames:YES];
//        
//        _faceProcessingQueue = dispatch_queue_create("faceDetectionQueue", DISPATCH_QUEUE_SERIAL);
//        
//        [_faceDetectionOutput setSampleBufferDelegate:self queue:_faceProcessingQueue];
//        
//        if ([self.captureSession canAddOutput:_faceDetectionOutput]) {
//            [self.captureSession addOutput:_faceDetectionOutput];
//        }
//
//        [[_faceDetectionOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];

        [self.captureSession startRunning];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskLandscapeRight);
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = self.view.bounds;
    
    [self.view.layer addSublayer:_previewLayer];
    
    //Get Preview Layer connection
    AVCaptureConnection *previewLayerConnection=_previewLayer.connection;
    
    if ([previewLayerConnection isVideoOrientationSupported]) {
        switch ([[UIApplication sharedApplication] statusBarOrientation]) {
            case UIInterfaceOrientationPortrait:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
                
            default:
                break;
        }
    }
}

//#pragma mark - Face processing
//
//// find where the video box is positioned within the preview layer based on the video size and gravity
//- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity
//                          frameSize:(CGSize)frameSize
//                       apertureSize:(CGSize)apertureSize
//{
//    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
//    CGFloat viewRatio = frameSize.width / frameSize.height;
//    
//    CGSize size = CGSizeZero;
//    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
//        if (viewRatio > apertureRatio) {
//            size.width = frameSize.width;
//            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
//        } else {
//            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
//            size.height = frameSize.height;
//        }
//    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
//        if (viewRatio > apertureRatio) {
//            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
//            size.height = frameSize.height;
//        } else {
//            size.width = frameSize.width;
//            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
//        }
//    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
//        size.width = frameSize.width;
//        size.height = frameSize.height;
//    }
//    
//	CGRect videoBox;
//	videoBox.size = size;
//	if (size.width < frameSize.width)
//		videoBox.origin.x = (frameSize.width - size.width) / 2;
//	else
//		videoBox.origin.x = (size.width - frameSize.width) / 2;
//    
//	if ( size.height < frameSize.height )
//		videoBox.origin.y = (frameSize.height - size.height) / 2;
//	else
//		videoBox.origin.y = (size.height - frameSize.height) / 2;
//    
//	return videoBox;
//}
//
//// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector
//// to detect features and for each draw the green border in a layer and set appropriate orientation
//- (void)drawFaces:(NSArray *)features
//      forVideoBox:(CGRect)clearAperture
//      orientation:(UIDeviceOrientation)orientation
//{
//	NSArray *sublayers = [NSArray arrayWithArray:[self.previewLayer sublayers]];
//	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
//	NSInteger featuresCount = [features count], currentFeature = 0;
//    
//	[CATransaction begin];
//	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
//    
//	// hide all the face layers
//	for ( CALayer *layer in sublayers ) {
//		if ( [[layer name] isEqualToString:@"FaceLayer"] )
//			[layer setHidden:YES];
//	}
//    
//	if ( featuresCount == 0 ) {
//		[CATransaction commit];
//		return; // early bail.
//	}
//    
//	CGSize parentFrameSize = self.view.bounds.size;
//	NSString *gravity = [self.previewLayer videoGravity];
//	BOOL isMirrored = [self.previewLayer.connection isVideoMirrored];
//	CGRect previewBox = [self videoPreviewBoxForGravity:gravity
//                                              frameSize:parentFrameSize
//                                           apertureSize:clearAperture.size];
//
//	for ( CIFaceFeature *ff in features ) {
//		// find the correct position for the square layer within the previewLayer
//		// the feature box originates in the bottom left of the video frame.
//		// (Bottom right if mirroring is turned on)
//		CGRect faceRect = [ff bounds];
//        
//		// flip preview width and height
//		CGFloat temp = faceRect.size.width;
//		faceRect.size.width = faceRect.size.height;
//		faceRect.size.height = temp;
//		temp = faceRect.origin.x;
//		faceRect.origin.x = faceRect.origin.y;
//		faceRect.origin.y = temp;
//		// scale coordinates so they fit in the preview box, which may be scaled
//		CGFloat widthScaleBy = previewBox.size.width / clearAperture.size.height;
//		CGFloat heightScaleBy = previewBox.size.height / clearAperture.size.width;
//		faceRect.size.width *= widthScaleBy;
//		faceRect.size.height *= heightScaleBy;
//		faceRect.origin.x *= widthScaleBy;
//		faceRect.origin.y *= heightScaleBy;
//        
//		if ( isMirrored )
//			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
//		else
//			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
//        
//		CALayer *featureLayer = nil;
//        
//		// re-use an existing layer if possible
//		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
//			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
//			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
//				featureLayer = currentLayer;
//				[currentLayer setHidden:NO];
//			}
//		}
//        
//		// create a new one if necessary
//		if ( !featureLayer ) {
//			featureLayer = [[CALayer alloc]init];
//			featureLayer.contents = (id)self.borderImage.CGImage;
//			[featureLayer setName:@"FaceLayer"];
//			[self.previewLayer addSublayer:featureLayer];
//			featureLayer = nil;
//		}
//		[featureLayer setFrame:faceRect];
//        
//		switch (orientation) {
//			case UIDeviceOrientationPortrait:
//				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
//				break;
//			case UIDeviceOrientationPortraitUpsideDown:
//				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
//				break;
//			case UIDeviceOrientationLandscapeLeft:
//				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
//				break;
//			case UIDeviceOrientationLandscapeRight:
//				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
//				break;
//			case UIDeviceOrientationFaceUp:
//			case UIDeviceOrientationFaceDown:
//			default:
//				break; // leave the layer in its last known orientation
//		}
//		currentFeature++;
//	}
//    
//	[CATransaction commit];
//}
//
//- (NSNumber *) exifOrientation: (UIDeviceOrientation) orientation
//{
//	int exifOrientation;
//    /* kCGImagePropertyOrientation values
//     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
//     by the TIFF and EXIF specifications -- see enumeration of integer constants.
//     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
//     
//     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
//     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
//    
//	enum {
//		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
//		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
//		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
//		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
//		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
//		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
//		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
//		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
//	};
//    
//	switch (orientation) {
//		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
//			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
//			break;
//		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
//            exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
//			break;
//		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
//            exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
//			break;
//		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
//		default:
//			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
//			break;
//	}
//    return [NSNumber numberWithInt:exifOrientation];
//}
//
//- (void)captureOutput:(AVCaptureOutput *)captureOutput
//didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
//       fromConnection:(AVCaptureConnection *)connection
//{
//	// get the image
//	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
//	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
//                                                      options:(__bridge NSDictionary *)attachments];
//	if (attachments) {
//		CFRelease(attachments);
//    }
//    
//    // make sure your device orientation is not locked.
//	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//    
//	NSDictionary *imageOptions = nil;
//    
//	imageOptions = [NSDictionary dictionaryWithObject:[self exifOrientation:curDeviceOrientation]
//                                               forKey:CIDetectorImageOrientation];
//    
//	NSArray *features = [self.faceDetector featuresInImage:ciImage
//                                                   options:imageOptions];
//
//    // get the clean aperture
//    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
//    // that represents image data valid for display.
//	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
//	CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
//    
//	dispatch_async(dispatch_get_main_queue(), ^(void) {
//		[self drawFaces:features
//            forVideoBox:cleanAperture
//            orientation:curDeviceOrientation];
//	});
//}

#pragma mark - Multipeer video delegate

- (void)raiseFramerate {
    
}

- (void)lowerFramerate {
    
}

- (void)multiPeerOutput:(AVCaptureMultipeerVideoDataOutput *)output didReceiveMessage:(NSString *)message {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
        
        [messageLabel setFont:[UIFont boldSystemFontOfSize:140.0]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setAlpha:0.0];
        
        [self.view addSubview:messageLabel];
        
        [UIView animateWithDuration:0.4
                         animations:^{
                             [messageLabel setAlpha:1.0];
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.2
                                                   delay:5.0
                                                 options:0
                                              animations:^{
                                                  [messageLabel setAlpha:0.0];
                                              } completion:^(BOOL finished) {
                                                  [messageLabel removeFromSuperview];
                                              }];
                         }];
    });
}

@end
