//
//  BoothGLView.h
//  CocoaGLBooth
//
//  Created by Julian on 1/29/10.
//  Copyright 2010 Julian Yu-Chung Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <QTKit/QTKit.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

	// Camera structure
typedef struct {
	GLdouble x,y,z;
} recVec;

typedef struct {
	recVec viewPos; // View position
	recVec viewDir; // View direction vector
	recVec viewUp; // View up direction
	recVec rotPoint; // Point to rotate about
	GLdouble aperture; // pContextInfo->camera aperture
	GLint viewWidth, viewHeight; // current window/screen height and width
} recCamera;

@interface BoothGLView : NSOpenGLView {
	CVImageBufferRef currentFrame;
	
    GLfloat lowerLeft[2];
    GLfloat lowerRight[2];
    GLfloat upperRight[2];
    GLfloat upperLeft[2];
	
		// Default img texture
	GLuint mytexName;
	GLuint imageWidth;
	GLuint imageHeight;
	
		// camera handling
	recCamera camera;
	GLfloat worldRotation [4];
	GLfloat objectRotation [4];
	GLfloat shapeSize;	
	
		// for animations
	NSTimer *timer;
	
		// for OpenGL fullscreen
	NSScreen                 *fullScreen;
	NSDictionary             *fullScreenOptions;	
}

- (void) prepareDefaultImgTexture;
- (void) setCurrentFrame:(CVImageBufferRef) aFrameRef;

- (void) setFullScreenMode;

#pragma mark Mouse Events
- (void) mouseDown:(NSEvent *)theEvent;
- (void) rightMouseDown:(NSEvent *)theEvent;
- (void) otherMouseDown:(NSEvent *)theEvent;
- (void) mouseUp:(NSEvent *)theEvent;
- (void) rightMouseUp:(NSEvent *)theEvent;
- (void) otherMouseUp:(NSEvent *)theEvent;
- (void) mouseDragged:(NSEvent *)theEvent;
- (void) scrollWheel:(NSEvent *)theEvent;
- (void) rightMouseDragged:(NSEvent *)theEvent;
- (void) otherMouseDragged:(NSEvent *)theEvent;

#pragma mark Utils
- (void) updateProjection;
- (void) updateModelView;
- (void) resizeGL;
- (void) resetCamera;

- (void) update;
- (void)animationTimer:(NSTimer *)timer;

@end
