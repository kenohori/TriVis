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

struct TriVisSceneWrapper;

@interface TriVisRenderer : NSObject {
@public
  // Scene
  struct TriVisSceneWrapper *sceneWrapper;
  
  // Shaders
  NSString *vertexShaderSource;
  NSString *fragmentShaderSource;
  
  // Animation
  CFAbsoluteTime renderTime;
  BOOL isAnimating;
  float movementSpeed, rotationSpeed;
}

- (void) loadInput:(unsigned int)numVertices vertices:(GLfloat *)vertices;
- (void) loadTriangulation:(unsigned int)numVertices vertices:(GLfloat *)vertices;
- (void) loadTaggedTriangulation:(unsigned int)numVertices vertices:(GLfloat *)vertices;
- (void) loadOutput:(unsigned int)numVertices vertices:(GLfloat *)vertices;

- (id) initWithDefaultFBO:(GLuint) defaultFBOName;
- (void) resizeWithFrame:(NSRect)frame;
- (void) render;
- (void) advanceTimeBy:(float)seconds;
- (void) dealloc;

- (void) moveX:(CGFloat)x andY:(CGFloat)y;
- (void) scaleBy:(CGFloat)s;
- (void) rotateBy:(CGFloat)degrees;
- (void) center;

- (void) viewMode:(unsigned int)mode;

- (void) movingLeft:(BOOL)ml;
- (void) movingRight:(BOOL)mr;
- (void) movingDown:(BOOL)md;
- (void) movingUp:(BOOL)mu;
- (void) rotatingCW:(BOOL)rcw;
- (void) rotatingCCW:(BOOL)rccw;

@end
