//
//  BoothGLView.h
//  CocoaGLBooth
//
//  Created by Julian on 1/29/10.
//  Copyright 2010 Julian Yu-Chung Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <QTKit/QTKit.h>

@interface BoothGLView : NSOpenGLView {
	CVImageBufferRef currentFrame;
	
    GLfloat lowerLeft[2];
    GLfloat lowerRight[2];
    GLfloat upperRight[2];
    GLfloat upperLeft[2];
	
		// Default img texture
	GLuint mytexName;
}

- (void) setCurrentFrame:(CVImageBufferRef) aFrameRef;
@end
