//
//  BoothGLView.m
//  CocoaGLBooth
//
//  Created by Julian on 1/29/10.
//  Copyright 2010 Julian Yu-Chung Chen. All rights reserved.
//

#import "BoothGLView.h"
#import "trackball.h"

#pragma mark -
#pragma mark Private - Constants

	//---------------------------------------------------------------------------

static const unichar kESCKey = 27;

#pragma mark -
#pragma mark Camera and interaction info
recVec gOrigin = {0.0, 0.0, 0.0};

	// single set of interaction flags and states
GLint gDollyPanStartPoint[2] = {0, 0};
GLfloat gTrackBallRotation [4] = {0.0f, 0.0f, 0.0f, 0.0f};
GLboolean gDolly = GL_FALSE;
GLboolean gPan = GL_FALSE;
GLboolean gTrackball = GL_FALSE;
BoothGLView *gTrackingViewInfo = NULL;

#pragma mark -
#pragma mark ---- OpenGL Utils ----
	// draw our simple cube based on current modelview and projection matrices
	// simple cube data
GLint cube_num_vertices = 8;

GLfloat cube_vertices [8][3] = {
	{1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}, {-1.0, 1.0, 1.0},
	{1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0} };

GLfloat cube_vertex_colors [8][3] = {
	{1.0, 1.0, 1.0}, {1.0, 1.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 1.0, 1.0},
	{1.0, 0.0, 1.0}, {1.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 1.0} };

GLint num_faces = 6;

short cube_faces [6][4] = {
	{3, 2, 1, 0}, {2, 3, 7, 6}, {0, 1, 5, 4}, {3, 0, 4, 7}, {1, 2, 6, 5}, {4, 5, 6, 7} };

static void drawCube (GLfloat fSize)
{
	float opacity = 1.0f;
	long f, i;
	if (1) {
		glColor4f (1.0, 0.5, 0.0, opacity);
		glBegin (GL_QUADS);
		for (f = 0; f < num_faces; f++)
			for (i = 0; i < 4; i++) {
				glColor4f (cube_vertex_colors[cube_faces[f][i]][0], cube_vertex_colors[cube_faces[f][i]][1], cube_vertex_colors[cube_faces[f][i]][2], opacity);
				glVertex3f(cube_vertices[cube_faces[f][i]][0] * fSize, cube_vertices[cube_faces[f][i]][1] * fSize, cube_vertices[cube_faces[f][i]][2] * fSize);
			}
		glEnd ();
	}
	if (1) {
		glLineWidth(1.5f);		
		glColor3f (1.0, 1.0, 1.0);
		for (f = 0; f < num_faces; f++) {
			glBegin (GL_LINE_LOOP);
			for (i = 0; i < 4; i++)
				glVertex3f(cube_vertices[cube_faces[f][i]][0] * fSize, cube_vertices[cube_faces[f][i]][1] * fSize, cube_vertices[cube_faces[f][i]][2] * fSize);
			glEnd ();
		}
	}
}

@implementation BoothGLView
	// update the projection matrix based on camera and view info
- (void) updateProjection
{
	GLdouble ratio, radians, wd2;
	GLdouble left, right, top, bottom, near, far;
	
    [[self openGLContext] makeCurrentContext];
	
		// set projection
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	near = -camera.viewPos.z - shapeSize * 0.5;
	if (near < 0.00001)
		near = 0.00001;
	far = -camera.viewPos.z + shapeSize * 0.5;
	if (far < 1.0)
		far = 1.0;
	radians = 0.0174532925 * camera.aperture / 2; // half aperture degrees to radians 
	wd2 = near * tan(radians);
	ratio = camera.viewWidth / (float) camera.viewHeight;
	if (ratio >= 1.0) {
		left  = -ratio * wd2;
		right = ratio * wd2;
		top = wd2;
		bottom = -wd2;	
	} else {
		left  = -wd2;
		right = wd2;
		top = wd2 / ratio;
		bottom = -wd2 / ratio;	
	}
	glFrustum (left, right, bottom, top, near, far);
}

	// updates the contexts model view matrix for object and camera moves
- (void) updateModelView
{
    [[self openGLContext] makeCurrentContext];
	
		// move view
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	gluLookAt (camera.viewPos.x, camera.viewPos.y, camera.viewPos.z,
			   camera.viewPos.x + camera.viewDir.x,
			   camera.viewPos.y + camera.viewDir.y,
			   camera.viewPos.z + camera.viewDir.z,
			   camera.viewUp.x, camera.viewUp.y ,camera.viewUp.z);
	
		// if we have trackball rotation to map (this IS the test I want as it can be explicitly 0.0f)
	if ((gTrackingViewInfo == self) && gTrackBallRotation[0] != 0.0f) 
		glRotatef (gTrackBallRotation[0], gTrackBallRotation[1], gTrackBallRotation[2], gTrackBallRotation[3]);
	else {
	}
		// accumlated world rotation via trackball
	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
		// object itself rotating applied after camera rotation
	glRotatef (objectRotation[0], objectRotation[1], objectRotation[2], objectRotation[3]);
	
	/* animation stuff
	 rRot[0] = 0.0f; // reset animation rotations (do in all cases to prevent rotating while moving with trackball)
	 rRot[1] = 0.0f;
	 rRot[2] = 0.0f;
	 */
}

#pragma mark -
#pragma mark Accessors
static bool isFirstFrame = YES;
- (void) setCurrentFrame:(CVImageBufferRef) aFrameRef
{
		// NSLog(@"BoothGLView setCurrentFrame.");

	currentFrame = CVBufferRetain(aFrameRef);
	
	if(currentFrame) {
		CGSize size = CVImageBufferGetDisplaySize(currentFrame);
		imageWidth = size.width;
		imageHeight = size.height;
		
		[[self openGLContext] makeCurrentContext];
		GLuint texName   = CVOpenGLTextureGetName(currentFrame);
		NSLog(@"Current frame texture name: %d", texName);
		
		CVOpenGLTextureGetCleanTexCoords(currentFrame, 
										 lowerLeft, 
										 lowerRight, 
										 upperRight, 
										 upperLeft);
		
			// DEBUG: test if the CVImageBuffer is valid
		if(isFirstFrame == YES) {
				// Create a NSImage
			NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:currentFrame]];
			NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
			[image addRepresentation:imageRep];
			
			NSData *tiffData = [image TIFFRepresentation];
			[tiffData writeToFile:@"/Users/julian/Desktop/FirstFrame.tiff" atomically:NO];
			
			isFirstFrame = NO;
		}		
	}
}

#pragma mark -
#pragma mark My texture quad rendering
- (void) drawDefaultQuad
{
	glPushMatrix();
	{
		glMatrixMode(GL_TEXTURE);
		glLoadIdentity();
		
		glMatrixMode(GL_MODELVIEW);		
		glScalef(2 * imageWidth / imageHeight, 2 * 1, 1.0f);
		
		glEnable(GL_TEXTURE_RECTANGLE_EXT);

		GLint texId = mytexName;
		
		if(currentFrame) {
				// CVOpenGLBufferAttach(currentFrame, [self openGLContext], face, level, screen);
			texId = CVOpenGLTextureGetName(currentFrame);
		}		
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texId);
		
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT,  GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT,  GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	
		
		glColor3f(1.0, 1.0, 1.0);
		glBegin(GL_QUADS);
		{
			glTexCoord2f(0, 0);
			glVertex2i(1, 1);

			glTexCoord2f(imageWidth, 0);			
			glVertex2i(-1, 1);
			
			glTexCoord2f(imageWidth, imageHeight);
			glVertex2i(-1, -1);
			
			glTexCoord2f(0, imageHeight);
			glVertex2i(1, -1);			
		}
		glEnd();		
	}
	glPopMatrix();
}

- (void) drawRect:(NSRect)rect
{		
		// setup viewport and prespective
	[self resizeGL]; // forces projection matrix update (does test for size changes)
	[self updateModelView];  // update model view matrix for object
	
		// clear our drawable
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// draw the scene
	drawCube (1.0f);
	[self drawDefaultQuad];
			
		// Optimization on flushing
	if ([self inLiveResize]) {
		glFlush ();
	} else {
		[[self openGLContext] flushBuffer];
	}
}

#pragma mark -
#pragma mark Public - Full Screen Mode
- (void) initFullScreen
{
	fullScreenOptions = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]  
													 forKey:NSFullScreenModeSetting] retain];
	
	fullScreen = [[NSScreen mainScreen] retain];
} // initFullScreen

	//---------------------------------------------------------------------------

- (void) fullScreenEnable
{
	[self enterFullScreenMode:fullScreen  
				  withOptions:fullScreenOptions];
} // fullScreenEnable

	//---------------------------------------------------------------------------

- (void) fullScreenDisable
{
	[self exitFullScreenModeWithOptions:fullScreenOptions];
} // fullScreenDisable

	//---------------------------------------------------------------------------

- (void) setFullScreenMode
{
	if( ![self isInFullScreenMode] )
	{
		[self fullScreenEnable];
	} // if
} // setFullScreenMode

	// set initial OpenGL state (current context is set)
	// called after context is created
- (void) prepareOpenGL
{
	// set to vbl sync
    GLint swapInt = 1;	
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
		// init GL stuff here
	glEnable(GL_DEPTH_TEST);

	glShadeModel(GL_SMOOTH);    
	glFrontFace(GL_CCW);
		// glEnable(GL_CULL_FACE);
		// glPolygonOffset (1.0f, 1.0f);
	
		// Point & line antialiasing
		// TODO: add polygon anti-aliasing: specialized blending function; or use accum buffer
	glEnable(GL_BLEND);
	glEnable(GL_POLYGON_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glHint(GL_LINE_SMOOTH_HINT, GL_DONT_CARE);
	glHint(GL_POLYGON_SMOOTH_HINT, GL_DONT_CARE);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_DONT_CARE);
		
		// default background color
	glClearColor(0.098f, 0.2f, 0.4f, 0.0f);

	[self resetCamera];
	shapeSize = 7.0f; // max radius of of objects
	
		// init fullscreen support
	[self initFullScreen];

		// Load the default texture
	[self prepareDefaultImgTexture];
	
		// init display link
	[self initDisplayLink];	
}
					
	// http://www.cocoabuilder.com/archive/cocoa/194722-opengl-texture-initialization-in-10-5.html
-(void) makeTextureFromImage:(NSImage*)theImg forTexture:(GLuint*)texName {	
    NSBitmapImageRep* bitmap = [NSBitmapImageRep alloc];
    int samplesPerPixel = 0;
    NSSize imgSize = [theImg size];
	
	imageWidth = imgSize.width;
	imageHeight = imgSize.height;
	
    [theImg lockFocus];
    [bitmap initWithFocusedViewRect:NSMakeRect(0.0, 0.0, imgSize.width, imgSize.height)];
    [theImg unlockFocus];
	
		// Set proper unpacking row length for bitmap.
    glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap pixelsWide]);
	
		// Set byte aligned unpacking (needed for 3 byte per pixel bitmaps).
    glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	
		// Generate a new texture name if one was not provided.
    if (*texName == 0) {
        glGenTextures (1, texName);
	}
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

- (void) prepareDefaultImgTexture
{
	NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"unixad" ofType:@"jpg" inDirectory:nil];
	NSImage *img = [[NSImage alloc] initWithContentsOfFile:imgPath];
	
	if (img == nil) {
		NSLog(@"Default NSImage is nil!");
	} else {
		NSLog(@"Build and bind default GL texture!");
		[self makeTextureFromImage:img forTexture:&mytexName];
		[img release];		
	}	
}

- (void) awakeFromNib
{
		// Default values
	currentFrame = nil;
	imageWidth = 640;
	imageHeight = 480;
		
		// start animation timer
	timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize	
}


#pragma mark -
#pragma mark Public - Key Events
- (void) keyDown:(NSEvent *)theEvent
{
	NSString  *characters = [theEvent charactersIgnoringModifiers];
    unichar    keyPressed = [characters characterAtIndex:0];
	
    if( keyPressed == kESCKey )
	{
		if( [self isInFullScreenMode] )
		{
			[self fullScreenDisable];
		}
		else
		{
			[self fullScreenEnable];
		}
    }
}

#pragma mark -
#pragma mark Mouse Events
	// move camera in z axis
-(void)mouseDolly: (NSPoint) location
{
	GLfloat dolly = (gDollyPanStartPoint[1] -location.y) * -camera.viewPos.z / 300.0f;
	camera.viewPos.z += dolly;
	if (camera.viewPos.z == 0.0) // do not let z = 0.0
		camera.viewPos.z = 0.0001;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

	// move camera in x/y plane
- (void)mousePan: (NSPoint) location
{
	GLfloat panX = (gDollyPanStartPoint[0] - location.x) / (900.0f / -camera.viewPos.z);
	GLfloat panY = (gDollyPanStartPoint[1] - location.y) / (900.0f / -camera.viewPos.z);
	camera.viewPos.x -= panX;
	camera.viewPos.y -= panY;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

- (void)mouseDown:(NSEvent *)theEvent // trackball
{
    if ([theEvent modifierFlags] & NSControlKeyMask) // send to pan
		[self rightMouseDown:theEvent];
	else if ([theEvent modifierFlags] & NSAlternateKeyMask) // send to dolly
		[self otherMouseDown:theEvent];
	else {
		if ([theEvent clickCount] >= 2) {
			if ([self isInFullScreenMode]) {
				[self fullScreenDisable];
			} else {
				[self fullScreenEnable];				
			}
		} else {
			NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			location.y = camera.viewHeight - location.y;
			gDolly = GL_FALSE; // no dolly
			gPan = GL_FALSE; // no pan
			gTrackball = GL_TRUE;
			startTrackball (location.x, location.y, 0, 0, camera.viewWidth, camera.viewHeight);
			gTrackingViewInfo = self;			
		}		
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent // pan
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_FALSE; // no dolly
	gPan = GL_TRUE; 
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

- (void)otherMouseDown:(NSEvent *)theEvent //dolly
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_TRUE;
	gPan = GL_FALSE; // no pan
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (gDolly) { // end dolly
		gDolly = GL_FALSE;
	} else if (gPan) { // end pan
		gPan = GL_FALSE;
	} else if (gTrackball) { // end trackball
		gTrackball = GL_FALSE;
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	} 
	gTrackingViewInfo = NULL;
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) {
		rollToTrackball (location.x, location.y, gTrackBallRotation);
		[self setNeedsDisplay: YES];
	} else if (gDolly) {
		[self mouseDolly: location];
		[self updateProjection];  // update projection matrix (not normally done on draw)
		[self setNeedsDisplay: YES];
	} else if (gPan) {
		[self mousePan: location];
		[self setNeedsDisplay: YES];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	float wheelDelta = [theEvent deltaX] +[theEvent deltaY] + [theEvent deltaZ];
	if (wheelDelta)
	{
		GLfloat deltaAperture = wheelDelta * -camera.aperture / 200.0f;
		camera.aperture += deltaAperture;
		if (camera.aperture < 0.1) // do not let aperture <= 0.1
			camera.aperture = 0.1;
		if (camera.aperture > 179.9) // do not let aperture >= 180
			camera.aperture = 179.9;
		[self updateProjection]; // update projection matrix
		[self setNeedsDisplay: YES];
	}
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

	// handles resizing of GL need context update and if the window dimensions change, a
	// a window dimension update, reseting of viewport and an update of the projection matrix
- (void) resizeGL
{
	NSRect rectView = [self bounds];
	
		// ensure camera knows size changed
	if ((camera.viewHeight != rectView.size.height) ||
	    (camera.viewWidth != rectView.size.width)) 
	{
		camera.viewHeight = rectView.size.height;
		camera.viewWidth = rectView.size.width;
		
		glViewport (0, 0, camera.viewWidth, camera.viewHeight);
		[self updateProjection];  // update projection matrix
	}
}

	// sets the camera data to initial conditions
- (void) resetCamera
{
	camera.aperture = 40;
	camera.rotPoint = gOrigin;
	
	camera.viewPos.x = 0.0;
	camera.viewPos.y = 0.0;
	camera.viewPos.z = -10.0;
	camera.viewDir.x = -camera.viewPos.x; 
	camera.viewDir.y = -camera.viewPos.y; 
	camera.viewDir.z = -camera.viewPos.z;
	
	camera.viewUp.x = 0;  
	camera.viewUp.y = 1; 
	camera.viewUp.z = 0;
}

#pragma mark -
#pragma mark Something about refresh the draw
- (void) update // window resizes, moves and display changes (resize, depth and display config change)
{
	/*
	msgTime	= getElapsedTime ();
	[msgStringTex setString:[NSString stringWithFormat:@"update at %0.1f secs", msgTime]  withAttributes:stanStringAttrib];
	 */
	
	[super update];
	
	/*
	if (![self inLiveResize])  {// if not doing live resize
		[self updateInfoString]; // to get change in renderers will rebuld string every time (could test for early out)
		getCurrentCaps (); // this call checks to see if the current config changed in a reasonably lightweight way to 
					       // prevent expensive re-allocations
	}
	 */
}

#pragma mark -
#pragma mark Something about animation
	// per-window timer function, basic time based animation preformed here
- (void)animationTimer:(NSTimer *)timer
{
	BOOL shouldDraw = YES;
	
	/*
	if (fAnimate) {
		CFTimeInterval deltaTime = CFAbsoluteTimeGetCurrent () - time;
		
		if (deltaTime > 10.0) // skip pauses
			return;
		else {
				// if we are not rotating with trackball in this window
			if (!gTrackball || (gTrackingViewInfo != self)) {
				[self updateObjectRotationForTimeDelta: deltaTime]; // update object rotation
			}
			shouldDraw = YES; // force redraw
		}
	}
	 */
	
		// time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
	
		// if we have current messages
	/*
	if (((getElapsedTime () - msgTime) < gMsgPresistance) || ((getElapsedTime () - gErrorTime) < gMsgPresistance)) {
		shouldDraw = YES; // force redraw
	}
*/
	
	if (YES == shouldDraw) {
		[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
	}
}

#pragma mark -
#pragma mark Display link callbacks
CVReturn MyDisplayLinkCallback (
								CVDisplayLinkRef displayLink,
								const CVTimeStamp *inNow,
								const CVTimeStamp *inOutputTime,
								CVOptionFlags flagsIn,
								CVOptionFlags *flagsOut,
								void *displayLinkContext)
{
	/*
	CVReturn error = [(MyVideoView*) displayLinkContext displayFrame:inOutputTime];
	return error;
	 */
	NSLog(@"My Display Link Callback.");
	
	return kCVReturnSuccess;
}

static CVReturn renderCallback(CVDisplayLinkRef displayLink, 
							   const CVTimeStamp *inNow, 
							   const CVTimeStamp *inOutputTime, 
							   CVOptionFlags flagsIn, 
							   CVOptionFlags *flagsOut, 
							   void *displayLinkContext)
{
	NSLog(@"render callback.");
	
	return kCVReturnSuccess;
		// return [(VideoView*)displayLinkContext renderTime:inOutputTime];	
}

#pragma mark -
#pragma mark Display Link init
- (void) initDisplayLink
{	
	NSLog(@"Init display link in BoothGLView.");

		// Create display link 
	CGOpenGLDisplayMask	totalDisplayMask = 0;
	int     virtualScreen;
	GLint    displayMask, accelerated;
	NSOpenGLPixelFormat	*openGLPixelFormat = [self pixelFormat];
	
		// build up list of displays from OpenGL's pixel format
	for (virtualScreen = 0; virtualScreen < [openGLPixelFormat  numberOfVirtualScreens]; virtualScreen++) {
		[openGLPixelFormat getValues:&displayMask forAttribute:NSOpenGLPFAScreenMask forVirtualScreen:virtualScreen];
        [openGLPixelFormat getValues:&accelerated forAttribute:NSOpenGLPFAAccelerated forVirtualScreen:virtualScreen];
        
        if (accelerated) {
            totalDisplayMask |= displayMask;
        }
	}
    
	CVReturn ret;
	ret = CVDisplayLinkCreateWithOpenGLDisplayMask(totalDisplayMask, &displayLink);
	
		// Set up display link callbacks 
	CVDisplayLinkSetOutputCallback(displayLink, renderCallback, self);
		
	/*
    CVReturn            error = kCVReturnSuccess;
    CGDirectDisplayID   displayID = CGMainDisplayID();// 1
	
    error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink);// 2
    if(error)
    {
        NSLog(@"DisplayLink created with error:%d", error);
        displayLink = NULL;
        return;
    }
	
    error = CVDisplayLinkSetOutputCallback(displayLink,// 3
										   MyDisplayLinkCallback, self);
	
		// create QTGLContext
		// OSStatus theError = QTOpenGLTextureContextCreate( NULL, NULL, 
		// 											 [[NSOpenGLView defaultPixelFormat] CGLPixelFormatObj], 
		// 											 NULL, &qtVisualContext);
	
	OSStatus theError = noErr;

	NSDictionary *targetDimensions = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:720.0], kQTVisualContextTargetDimensions_WidthKey, 
									  [NSNumber numberWithFloat:480.0], kQTVisualContextTargetDimensions_HeightKey, nil];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: targetDimensions,  kQTVisualContextTargetDimensionsKey,
								displayColorSpace, kQTVisualContextOutputColorSpaceKey, nil];

	error = QTOpenGLTextureContextCreate(kCFAllocatorDefault, (CGLContextObj)[[self openGLContext] CGLContextObj],
										 (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj],
										 (CFDictionaryRef)attributes,
										 &qtVisualContext);
		
	if(qtVisualContext == NULL)
	{
        NSLog(@"QTVisualContext creation failed with error:%d", theError);
        return;
    }
	 */
}

@end
