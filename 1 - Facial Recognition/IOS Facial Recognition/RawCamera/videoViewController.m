//
//  videoViewController.m
//  RawCamera
//
//  Created by Alan Gonzalez on 11/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "videoViewController.h"

@implementation videoViewController
@synthesize imageView;
@synthesize vidUIView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    //used in the captureoutput method below.
    detector = [CIDetector detectorOfType:CIDetectorTypeFace 
                                  context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    square = [UIImage imageNamed:@"hair"];
    mouth = [UIImage imageNamed:@"lips"];
    rightEye = [UIImage imageNamed:@"eye"];
    leftEye = [UIImage imageNamed:@"eye"];
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    self.vidUIView = nil;
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //AVCapture instance wraps the AVCcaptureDevice and AVCaptureDeviceInput and AVCaptureOutput into a viewing session.
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPreset640x480];
    //Chosing the Mediatype to Accept (Change The last parameter to get audio.
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        //when it iterates to the dront camera set capturedevice to the front camera
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    NSLog(@"%@", captureDevice);
    
    NSError *error = nil;
    
    //Takes the AVCaptureDevice as a parameter to create an input.
    AVCaptureDeviceInput *vidInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    
    AVCaptureVideoDataOutput * vidOutput = [[AVCaptureVideoDataOutput alloc] init];
    [vidOutput setAlwaysDiscardsLateVideoFrames:YES];
    [vidOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; 	
    
    [vidOutput setSampleBufferDelegate:self queue:dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)];

    
    //Preview layer is kind of an output, but not really. The output is generally a file of some sort (movie, recording, etc)
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    //Making the Frame
    viewRect = CGRectMake(0, 0, 340, 480);
    [previewLayer setFrame:[vidUIView.layer bounds]];
    [vidUIView.layer addSublayer:previewLayer];
    
    //video session add imput, output and start it
    if(vidInput){
        [session addInput:vidInput];
        [session addOutput:vidOutput];
        [session startRunning];
            NSLog(@"running");
        //  [session addOutput:vidOut];
    }else{
        NSLog(@"Error");
    }
	
    //temporary.
                     
}


static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	ciimage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
    
    

//    //scales the image that is seen by the cidetector down
//    CIImage *myCiImage = [ciimage imageByApplyingTransform:CGAffineTransformMakeScale(.38, -.68)];
//    //because the scaling for y is negative it mirrors on the left side. I then have to translate (move) the image
//    //over by its width.
//    CIImage *transImage = [myCiImage imageByApplyingTransform:CGAffineTransformMakeTranslation(0, 320)];

    
    //options for features array below. It changes the orientation of the image 90 degrees(option 6)
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:6]
                                               forKey:CIDetectorImageOrientation];
    //grabs features from detectore wich is implemented in viewdidload above. uses he options above
    NSArray *features = [detector featuresInImage:ciimage options:imageOptions];
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:UIDeviceOrientationPortrait];
	});
}

- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
        if ( [[layer name] isEqualToString:@"RightEyeLayer"] )
			[layer setHidden:YES];
        if ( [[layer name] isEqualToString:@"LeftEyeLayer"] )
			[layer setHidden:YES];
        if ( [[layer name] isEqualToString:@"MouthLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [vidUIView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	BOOL isMirrored = [previewLayer isMirrored];
	CGRect previewBox = [self videoPreviewBoxForGravity:gravity
                                                                 frameSize:parentFrameSize
                                                              apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
        
        if (ff.hasLeftEyePosition) {
            CGRect eyeRect;
            CGPoint eyePoint = ff.leftEyePosition;
            eyeRect = CGRectMake(eyePoint.x, eyePoint.y, 40, 40);
            CGFloat temp = eyeRect.size.width;
            eyeRect.size.width = eyeRect.size.height;
            eyeRect.size.height = temp;
            temp = eyeRect.origin.x;
            eyeRect.origin.x = eyeRect.origin.y;
            eyeRect.origin.y = temp;
            // scale coordinates so they fit in the preview box, which may be scaled
            CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
            CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
            eyeRect.size.width *= widthScaleBy;
            eyeRect.size.height *= heightScaleBy;
            eyeRect.origin.x *= widthScaleBy;
            eyeRect.origin.y *= heightScaleBy;
//            leftEyeRect.origin.y -= 75;
            eyeRect.size.width += 25;
            eyeRect.size.height += 25;
            eyeRect.origin.x -= 25;
            eyeRect.origin.y -= 25;
            
            if ( isMirrored )
                eyeRect = CGRectOffset(eyeRect, previewBox.origin.x + previewBox.size.width - eyeRect.size.width - (eyeRect.origin.x * 2), previewBox.origin.y);
            else
                eyeRect = CGRectOffset(eyeRect, previewBox.origin.x, previewBox.origin.y);
            
            CALayer *featureLayer = nil;
            
            // re-use an existing layer if possible
            while ( !featureLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:@"LeftEyeLayer"] ) {
                    featureLayer = currentLayer;
                    [currentLayer setHidden:NO];
                }
            }
            
            // create a new one if necessary
            if ( !featureLayer ) {
                featureLayer = [CALayer new];
                [featureLayer setContents:(id)[leftEye CGImage]];
                [featureLayer setName:@"LeftEyeLayer"];
                [previewLayer addSublayer:featureLayer];
            }
            [featureLayer setFrame:eyeRect];
        }
        
        //RIGHT EYE
        if (ff.hasRightEyePosition) {
            CGRect eyeRect;
            CGPoint eyePoint = ff.rightEyePosition;
            eyeRect = CGRectMake(eyePoint.x, eyePoint.y, 40, 40);
            CGFloat temp = eyeRect.size.width;
            eyeRect.size.width = eyeRect.size.height;
            eyeRect.size.height = temp;
            temp = eyeRect.origin.x;
            eyeRect.origin.x = eyeRect.origin.y;
            eyeRect.origin.y = temp;
            // scale coordinates so they fit in the preview box, which may be scaled
            CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
            CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
            eyeRect.size.width *= widthScaleBy;
            eyeRect.size.height *= heightScaleBy;
            eyeRect.origin.x *= widthScaleBy;
            eyeRect.origin.y *= heightScaleBy;
            //            leftEyeRect.origin.y -= 75;
            eyeRect.size.width += 25;
            eyeRect.size.height += 25;
            eyeRect.origin.x -= 25;
            eyeRect.origin.y -= 25;
            
            if ( isMirrored )
                eyeRect = CGRectOffset(eyeRect, previewBox.origin.x + previewBox.size.width - eyeRect.size.width - (eyeRect.origin.x * 2), previewBox.origin.y);
            else
                eyeRect = CGRectOffset(eyeRect, previewBox.origin.x, previewBox.origin.y);
            
            CALayer *featureLayer = nil;
            
            // re-use an existing layer if possible
            while ( !featureLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:@"RightEyeLayer"] ) {
                    featureLayer = currentLayer;
                    [currentLayer setHidden:NO];
                }
            }
            
            // create a new one if necessary
            if ( !featureLayer ) {
                featureLayer = [CALayer new];
                [featureLayer setContents:(id)[rightEye CGImage]];
                [featureLayer setName:@"RightEyeLayer"];
                [previewLayer addSublayer:featureLayer];
            }
            [featureLayer setFrame:eyeRect];
        }
        
        //MOUTH
        if (ff.hasMouthPosition) {
            CGRect eyeRect;
            CGPoint eyePoint = ff.mouthPosition;
            eyeRect = CGRectMake(eyePoint.x, eyePoint.y, 40, 60);
            CGFloat temp = eyeRect.size.width;
            eyeRect.size.width = eyeRect.size.height;
            eyeRect.size.height = temp;
            temp = eyeRect.origin.x;
            eyeRect.origin.x = eyeRect.origin.y;
            eyeRect.origin.y = temp;
            // scale coordinates so they fit in the preview box, which may be scaled
            CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
            CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
            eyeRect.size.width *= widthScaleBy;
            eyeRect.size.height *= heightScaleBy;
            eyeRect.origin.x *= widthScaleBy;
            eyeRect.origin.y *= heightScaleBy;
            //            leftEyeRect.origin.y -= 75;
            eyeRect.size.width += 25;
            eyeRect.size.height += 25;
            eyeRect.origin.x -= 25;
            eyeRect.origin.y -= 25;
            
            if ( isMirrored )
                eyeRect = CGRectOffset(eyeRect, previewBox.origin.x + previewBox.size.width - eyeRect.size.width - (eyeRect.origin.x * 2), previewBox.origin.y);
            else
                eyeRect = CGRectOffset(eyeRect, previewBox.origin.x, previewBox.origin.y);
            
            CALayer *featureLayer = nil;
            
            // re-use an existing layer if possible
            while ( !featureLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:@"MouthLayer"] ) {
                    featureLayer = currentLayer;
                    [currentLayer setHidden:NO];
                }
            }
            
            // create a new one if necessary
            if ( !featureLayer ) {
                featureLayer = [CALayer new];
                [featureLayer setContents:(id)[mouth CGImage]];
                [featureLayer setName:@"MouthLayer"];
                [previewLayer addSublayer:featureLayer];
            }
            [featureLayer setFrame:eyeRect];
        }

        
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        faceRect.origin.y -= 75;
        faceRect.origin.y -= 15;
        faceRect.size.width += 35;
		faceRect.size.height += 35;
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(id)[square CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[previewLayer addSublayer:featureLayer];
		}
		[featureLayer setFrame:faceRect];
		
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
	
	[CATransaction commit];
}

// find where the video box is positioned within the preview layer based on the video size and gravity
- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (IBAction)frontrearseg:(UISegmentedControl*)sender {
    AVCaptureDevicePosition desiredPosition;
	if (sender.selectedSegmentIndex == 1)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
				[[previewLayer session] removeInput:oldInput];
			}
			[[previewLayer session] addInput:input];
			[[previewLayer session] commitConfiguration];
			break;
		}
	}
//	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}
@end
