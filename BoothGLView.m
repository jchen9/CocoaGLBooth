//
//  BoothGLView.m
//  CocoaGLBooth
//
//  Created by Julian on 1/29/10.
//  Copyright 2010 Julian Yu-Chung Chen. All rights reserved.
//

#import "BoothGLView.h"

#define kWIDTH  1094
#define kHEIGHT 720

@implementation BoothGLView

#pragma mark Accessors
- (void) setCurrentFrame:(CVImageBufferRef) aFrameRef
{
	currentFrame = aFrameRef;
	
	if (currentFrame == nil) {
		NSLog(@"Nil currentFrame after setting!!!");
		return;
	}	
	
	NSLog(@"Has currentFrame!!!");
	
        // Returns the texture coordinates for the 
        // part of the image that should be displayed
	/*
	CVOpenGLTextureGetCleanTexCoords(currentFrame, 
									 lowerLeft, 
									 lowerRight, 
									 upperRight, 
									 upperLeft);	
	 
	lowerLeft[0] = 0;  lowerLeft[1] = 0;
	lowerRight[0] = 1; lowerRight[1] = 0;
	upperRight[0] = 1; upperRight[1] = 1;
	upperLeft[0] = 0;  upperLeft[1] = 1;
	*/
	
	[self setNeedsDisplay:YES];
}

#pragma mark OpenGL initialization
- (void) prepareGLStates
{
	NSLog(@"Prepare GL states");
	
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	
	glShadeModel( GL_SMOOTH );					// enable smooth shading
    glEnable( GL_DEPTH_TEST );					// enable depth testing
	
	glDisable( GL_LIGHTING );
	
    glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );		// black background
    glClearStencil( 0 );						// clear stencil image
	glClearDepth( 1.0f );						// 0 is near, 1 is far
    glDepthFunc( GL_LEQUAL );					// type of depth test to do
	
		// For some OpenGL implementations, glAttribs.texture coordinates generated 
		// during rasterization aren't perspective correct. However, you 
		// can usually make them perspective correct by calling the API
		// glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST).  Colors 
		// generated at the rasterization stage aren't perspective correct 
		// in almost every OpenGL implementation, / and can't be made so. 
		// For this reason, you're more likely to encounter this problem 
		// with colors than glAttribs.texture coordinates.
	
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
} // prepareOpenGLStates

#pragma mark Rendering
- (void) drawRect:(NSRect)rect
{	
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glOrtho(-kWIDTH, kWIDTH, -kHEIGHT, kHEIGHT, -1.0, 1.0);
	
		// Access texture
		// int targetId = CVOpenGLTextureGetTarget(currentFrame);
		// NSLog(@"target id: %d, %d, %.2f", targetId, GL_TEXTURE_2D, sizeof(currentFrame));

	/*
	 // glEnable(targetId);
		glBindTexture(CVOpenGLTextureGetTarget(currentFrame),
					  CVOpenGLTextureGetName(currentFrame));
	 */

	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();

	NSLog(@"My texture id: %d", mytexName);
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	glBindTexture (GL_TEXTURE_RECTANGLE_EXT, mytexName);		
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT,  GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT,  GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	
		// glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
		
	glColor3f(1.0, 1.0, 1.0);
	glBegin(GL_QUADS);
	{
		glTexCoord2f(0, 0);
		glVertex2i(-kWIDTH/2,  kHEIGHT/2);
		
		glTexCoord2f(0, 720);
		glVertex2i(-kWIDTH/2, -kHEIGHT/2);
		
		glTexCoord2f(1094, 720);
		glVertex2i( kWIDTH/2, -kHEIGHT/2);
		
		glTexCoord2f(1094, 0);
		glVertex2i( kWIDTH/2,  kHEIGHT/2);
	}
	glEnd();
	
	glFlush();	
}
					
	// Call this when you have GL context, probably in prepareGL() but not in awakeFromNib()
	// http://www.cocoabuilder.com/archive/cocoa/194722-opengl-texture-initialization-in-10-5.html
-(void) makeTextureFromImage:(NSImage*)theImg forTexture:(GLuint*)texName {	
    NSBitmapImageRep* bitmap = [NSBitmapImageRep alloc];
    int samplesPerPixel = 0;
    NSSize imgSize = [theImg size];
	
    [theImg lockFocus];
    [bitmap initWithFocusedViewRect:NSMakeRect(0.0, 0.0, imgSize.width, imgSize.height)];
    [theImg unlockFocus];
	
		// Set proper unpacking row length for bitmap.
    glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap pixelsWide]);
	
		// Set byte aligned unpacking (needed for 3 byte per pixel bitmaps).
    glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	
		// Generate a new texture name if one was not provided.
    if (*texName == 0)
        glGenTextures (1, texName);
    glBindTexture (GL_TEXTURE_RECTANGLE_EXT, *texName);
	
		// Non-mipmap filtering (redundant for texture_rectangle).
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER,  GL_LINEAR);
    samplesPerPixel = [bitmap samplesPerPixel];
	
		// Nonplanar, RGB 24 bit bitmap, or RGBA 32 bit bitmap.
    if(![bitmap isPlanar] && (samplesPerPixel == 3 || samplesPerPixel == 4)) {
		
        glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0,
					 samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
					 [bitmap pixelsWide],
					 [bitmap pixelsHigh],
					 0,
					 samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
					 GL_UNSIGNED_BYTE,
					 [bitmap bitmapData]);
    } else {
			// Handle other bitmap formats.
    }
	
		// Clean up.
    [bitmap release];
}

#pragma mark Overrides
- (void) prepareOpenGL
{
	NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"unixad" ofType:@"jpg" inDirectory:nil];
	NSImage *img = [[NSImage alloc] initWithContentsOfFile:imgPath];
	
	if (img == nil) {
		NSLog(@"NSImage is nil!!!");
	} else {
		NSLog(@"Build and bind GL texture!");
		[self makeTextureFromImage:img forTexture:&mytexName];
		[img release];		
	}	
}

- (void) awakeFromNib
{
}

@end
