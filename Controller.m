//
//  Controller.m
//  CocoaGLBooth
//
//  Created by Julian on 1/29/10.
//  Copyright 2010 Julian Yu-Chung Chen. All rights reserved.
//

#import "Controller.h"


@implementation Controller

- (void) initQTCapture
{
		// Create the capture session
    
	mCaptureSession = [[QTCaptureSession alloc] init];
    
		// Connect inputs and outputs to the session	
    
	BOOL success = NO;
	NSError *error;
	
		// Find a video device  
    
    QTCaptureDevice *videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    success = [videoDevice open:&error];
    
    
		// If a video input device can't be found or opened, try to find and open a muxed input device
    
	if (!success) {
		videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
		success = [videoDevice open:&error];		
    }
    
    if (!success) {
        videoDevice = nil;
			// Handle error
        
    }
    
    if (videoDevice) {
			//Add the video device to the session as a device input
		
		mCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
		success = [mCaptureSession addInput:mCaptureVideoDeviceInput error:&error];
		if (!success) {
				// Handle error
		}
        
			// If the video device doesn't also supply audio, add an audio device input to the session
        /*
        if (![videoDevice hasMediaType:QTMediaTypeSound] && ![videoDevice hasMediaType:QTMediaTypeMuxed]) {
            
            QTCaptureDevice *audioDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeSound];
            success = [audioDevice open:&error];
            
            if (!success) {
                audioDevice = nil;
					// Handle error
            }
            
            if (audioDevice) {
                mCaptureAudioDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:audioDevice];
                
                success = [mCaptureSession addInput:mCaptureAudioDeviceInput error:&error];
                if (!success) {
						// Handle error
                }
            }
        }
		 */
        
			// Create the movie file output and add it to the session
			// mCapturePreviewOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
		mCapturePreviewOutput = [[QTCaptureVideoPreviewOutput alloc] init];
			// [mCapturePreviewOutput setVisualContext:textureContext forConnection:[[mCapturePreviewOutput connections] lastObject]];
		[mCapturePreviewOutput setDelegate:self];

		success = [mCaptureSession addOutput:mCapturePreviewOutput error:&error];
		if(!success) {
			NSLog(@"Init QTCaptureVideoPreviewOutput failed.");
		}
				
        /*
        mCaptureMovieFileOutput = [[QTCaptureMovieFileOutput alloc] init];
        success = [mCaptureSession addOutput:mCaptureMovieFileOutput error:&error];
        if (!success) {
				// Handle error
        }
        
        [mCaptureMovieFileOutput setDelegate:self];
				
			// Set the compression for the audio/video that is recorded to the hard disk.
		
		NSEnumerator *connectionEnumerator = [[mCaptureMovieFileOutput connections] objectEnumerator];
		QTCaptureConnection *connection;
		
			// iterate over each output connection for the capture session and specify the desired compression
		while ((connection = [connectionEnumerator nextObject])) {
			NSString *mediaType = [connection mediaType];
			QTCompressionOptions *compressionOptions = nil;
				// specify the video compression options
				// (note: a list of other valid compression types can be found in the QTCompressionOptions.h interface file)
			if ([mediaType isEqualToString:QTMediaTypeVideo]) {
					// use H.264
				compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptions240SizeH264Video"];
					// specify the audio compression options
			} else if ([mediaType isEqualToString:QTMediaTypeSound]) {
					// use AAC Audio
				compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsHighQualityAACAudio"];
			}
			
				// set the compression options for the movie file output
			[mCaptureMovieFileOutput setCompressionOptions:compressionOptions forConnection:connection];
		} 
		 */
			// Associate the capture view in the UI with the session
        
        [mCaptureView setCaptureSession:mCaptureSession];       
        [mCaptureSession startRunning];        
	}	
}

	// Handle window closing notifications for your device input

- (void)windowWillClose:(NSNotification *)notification
{
	
	[mCaptureSession stopRunning];
    
    if ([[mCaptureVideoDeviceInput device] isOpen])
        [[mCaptureVideoDeviceInput device] close];
    
	/*
    if ([[mCaptureAudioDeviceInput device] isOpen])
        [[mCaptureAudioDeviceInput device] close];
    */
}

	// Handle deallocation of memory for your capture objects
- (void)dealloc
{
	[mCaptureSession release];
	[mCaptureVideoDeviceInput release];
	[mCapturePreviewOutput release];
		// [mCaptureAudioDeviceInput release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self initQTCapture];
}

#pragma mark Delegate Method for QTCaptureVideoPreviewOutput
- (void)captureOutput:(QTCaptureOutput *)captureOutput 
  didOutputVideoFrame:(CVImageBufferRef)videoFrame 
	 withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
	   fromConnection:(QTCaptureConnection *)connection
{
		// DEBUG: about videoFrame's textureCoord
	/*
	NSLog(@"[Async] capture output delegate called!");
	 
	GLfloat lowerLeft[2];
	GLfloat lowerRight[2];
	GLfloat upperRight[2];
	GLfloat upperLeft[2];
	
	CVOpenGLTextureGetCleanTexCoords(mCurrentImageBuffer, 
									 lowerLeft, 
									 lowerRight, 
									 upperRight, 
									 upperLeft);		 
	
	NSLog(@"lowerLeft:  %.2f\t%.2f", lowerLeft[0],  lowerLeft[1]);
	NSLog(@"lowerRight: %.2f\t%.2f", lowerRight[0], lowerRight[1]);
	NSLog(@"upperRight: %.2f\t%.2f", upperRight[0], upperRight[1]);
	NSLog(@"upperLeft:  %.2f\t%.2f", upperLeft[0],  upperLeft[1]);
	*/
	
		// Store the latest frame
		// This must be done in a @synchronized block 
		// because this delegate method is not called on the main thread
    CVImageBufferRef imageBufferToRelease;    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {
        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;			
		
		[boothView setCurrentFrame:mCurrentImageBuffer];
    }
		
    CVBufferRelease(imageBufferToRelease);
}

#pragma mark IBActions
- (IBAction) fullScreenMode:(id)sender
{
	[boothView setFullScreenMode];
}

- (IBAction) captureStillImage:(id)sender
{
    CVImageBufferRef imageBuffer;
    
    @synchronized (self) {
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);
    }
    
    if (imageBuffer) {
			// Create an NSImage and add it to the movie
        NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];
        NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
        [image addRepresentation:imageRep];
        CVBufferRelease(imageBuffer);
        		
		[stillImageView setImage:image];
		[stillImageView setNeedsDisplay:YES];
    }	
}

@end
