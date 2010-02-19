//
//  Controller.h
//  CocoaGLBooth
//
//  Created by Julian on 1/29/10.
//  Copyright 2010 Julian Yu-Chung Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#import "BoothGLView.h"

@interface Controller : NSObject {
		// Outlets for UI elements
	IBOutlet QTCaptureView  *mCaptureView;
	IBOutlet BoothGLView	*boothView;
	IBOutlet NSImageView	*stillImageView;
	
		// For QuickTime capture
	QTCaptureSession            *mCaptureSession;
	QTCaptureVideoPreviewOutput *mCapturePreviewOutput;
		// QTCaptureDecompressedVideoOutput *mCapturePreviewOutput;	
    QTCaptureDeviceInput        *mCaptureVideoDeviceInput;
		// QTCaptureDeviceInput        *mCaptureAudioDeviceInput;	
	
		// Current frame buffer	
	CVImageBufferRef                    mCurrentImageBuffer;		
}

- (IBAction) fullScreenMode:(id)sender;
- (IBAction) captureStillImage:(id)sender;
@end
