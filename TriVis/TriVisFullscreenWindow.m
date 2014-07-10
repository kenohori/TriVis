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

#import "TriVisFullscreenWindow.h"

@implementation TriVisFullscreenWindow

-(id) init {
	// Create a screen-sized window on the display you want to take over
	NSRect screenRect = [[NSScreen mainScreen] frame];
  
	// Initialize the window making it size of the screen and borderless
	self = [super initWithContentRect:screenRect
                          styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                              defer:YES];
  
	// Set the window level to be above the menu bar to cover everything else
	[self setLevel:NSMainMenuWindowLevel+1];
  
	// Set opaque
	[self setOpaque:YES];
  
	// Hide this when user switches to another window (or app)
	[self setHidesOnDeactivate:YES];
  
	return self;
}

- (BOOL) canBecomeKeyWindow {
	// Return yes so that this borderless window can receive input
	return YES;
}

- (void) keyDown:(NSEvent *)event {
	// Implement keyDown since controller will not get [ESC] key event which
	// the controller uses to kill fullscreen
	[[self windowController] keyDown:event];
}

@end
