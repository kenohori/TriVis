/*
 Copyright (c) 2014 Ken Arroyo Ohori
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "TriVisGLView.h"

@implementation TriVisGLView

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime {
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  
  [[self openGLContext] makeCurrentContext];
  
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main
	// thread. Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
  
	[renderer advanceTimeBy:(currentTime-renderer->renderTime)];
  
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
  renderer->renderTime = currentTime;
  
  [self drawView];
	return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext) {
  CVReturn result = [(__bridge TriVisGLView *)displayLinkContext getFrameForTime:outputTime];
  return result;
}

- (void) awakeFromNib {
  NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 32,
    NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
		0
	};
	
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
	if (!pf) {
		NSLog(@"No OpenGL pixel format");
	}
  
  NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
  
  // When we're using a CoreProfile context, crash if we call a legacy OpenGL function
	// This will make it much more obvious where and when such a function call is made so
	// that we can remove such calls.
	// Without this we'd simply get GL_INVALID_OPERATION error for calling legacy functions
	// but it would be more difficult to see where that function was called.
	CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
	
  [self setPixelFormat:pf];
  
  [self setOpenGLContext:context];
  
#if SUPPORT_RETINA_RESOLUTION
  // Opt-In to Retina resolution
  [self setWantsBestResolutionOpenGLSurface:YES];
#endif // SUPPORT_RETINA_RESOLUTION
}

- (void) prepareOpenGL {
	[super prepareOpenGL];
	
	// Make all the OpenGL calls to setup rendering
	//  and build the necessary rendering objects
	[self initGL];
	
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// Register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:[self window]];
}

- (void) windowWillClose:(NSNotification*)notification {
	// Stop the display link when the window is closing because default
	// OpenGL render buffers will be destroyed.  If display link continues to
	// fire without renderbuffers, OpenGL draw calls will set errors.
	
	CVDisplayLinkStop(displayLink);
}

- (void) initGL {
	// The reshape function may have changed the thread to which our OpenGL
	// context is attached before prepareOpenGL and initGL are called.  So call
	// makeCurrentContext to ensure that our OpenGL context current to this
	// thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
	// to [self openGLContext])
	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	// Init our renderer.  Use 0 for the defaultFBO which is appropriate for
	// OSX (but not iOS since iOS apps must create their own FBO)
	renderer = [[TriVisRenderer alloc] initWithDefaultFBO:0];
}

- (void) reshape {
	[super reshape];
	
	// We draw on a secondary thread through the display link. However, when
	// resizing the view, -drawRect is called on the main thread.
	// Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing.
	CGLLockContext([[self openGLContext] CGLContextObj]);
  
	// Get the view size in Points
	NSRect viewRectPoints = [self bounds];
  
#if SUPPORT_RETINA_RESOLUTION
  
  // Rendering at retina resolutions will reduce aliasing, but at the potential
  // cost of framerate and battery life due to the GPU needing to render more
  // pixels.
  
  // Any calculations the renderer does which use pixel dimentions, must be
  // in "retina" space.  [NSView convertRectToBacking] converts point sizes
  // to pixel sizes.  Thus the renderer gets the size in pixels, not points,
  // so that it can set it's viewport and perform and other pixel based
  // calculations appropriately.
  // viewRectPixels will be larger (2x) than viewRectPoints for retina displays.
  // viewRectPixels will be the same as viewRectPoints for non-retina displays
  NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
  
#else //if !SUPPORT_RETINA_RESOLUTION
  
  // App will typically render faster and use less power rendering at
  // non-retina resolutions since the GPU needs to render less pixels.  There
  // is the cost of more aliasing, but it will be no-worse than on a Mac
  // without a retina display.
  
  // Points:Pixels is always 1:1 when not supporting retina resolutions
  NSRect viewRectPixels = viewRectPoints;
  
#endif // !SUPPORT_RETINA_RESOLUTION
  
	// Set the new dimensions in our renderer
	[renderer resizeWithFrame:viewRectPixels];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


- (void)renewGState {
	// Called whenever graphics state updated (such as window resize)
	
	// OpenGL rendering is not synchronous with other rendering on the OSX.
	// Therefore, call disableScreenUpdatesUntilFlush so the window server
	// doesn't render non-OpenGL content in the window asynchronously from
	// OpenGL content, which could cause flickering.  (non-OpenGL content
	// includes the title bar and drawing done by the app with other APIs)
	[[self window] disableScreenUpdatesUntilFlush];
  
	[super renewGState];
}

- (void) drawRect: (NSRect) theRect {
	// Called during resize operations
	
	// Avoid flickering during resize by drawiing
	[self drawView];
}

- (void) drawView {
	[[self openGLContext] makeCurrentContext];
  
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main
	// thread. Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
  
	[renderer render];
  
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

@end
