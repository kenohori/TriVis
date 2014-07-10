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

#import "TriVisRenderer.h"
#import "TriVisScene.h"

struct TriVisSceneWrapper {
  TriVisScene *scene;
};

@implementation TriVisRenderer

- (void) loadInput:(unsigned int)numVertices vertices:(GLfloat *)vertices {
  sceneWrapper->scene->loadInput(numVertices, vertices);
}

- (void) loadTriangulation:(unsigned int)numVertices vertices:(GLfloat *)vertices {
  sceneWrapper->scene->loadTriangulation(numVertices, vertices);
}

- (void) loadTaggedTriangulation:(unsigned int)numVertices vertices:(GLfloat *)vertices {
  sceneWrapper->scene->loadTaggedTriangulation(numVertices, vertices);
}

- (void) loadOutput:(unsigned int)numVertices vertices:(GLfloat *)vertices {
  sceneWrapper->scene->loadOutput(numVertices, vertices);
}

- (void) resizeWithFrame:(NSRect)frame {
//  NSLog(@"[TriVisRenderer resizeWithFrame:NSRect(%f, %f, %f, %f)]", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
  
  sceneWrapper->scene->resize(frame.size.width, frame.size.height);
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName {
//  NSLog(@"[TriVisRenderer initWithDefaultFBO:%d]", defaultFBOName);
  
  // Allocate the scene object
  sceneWrapper = new TriVisSceneWrapper();
  sceneWrapper->scene = new TriVisScene();
  
  NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"vertex" ofType:@"glsl"];
  NSStringEncoding encoding;
  NSError *error;
  vertexShaderSource = [NSString stringWithContentsOfFile:vertexShaderPath usedEncoding:&encoding error:&error];
  sceneWrapper->scene->createVertexShader([vertexShaderSource UTF8String]);
  
  
  NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"fragment" ofType:@"glsl"];
  fragmentShaderSource = [NSString stringWithContentsOfFile:fragmentShaderPath usedEncoding:&encoding error:&error];
  sceneWrapper->scene->createFragmentShader([fragmentShaderSource UTF8String]);
  
  sceneWrapper->scene->initGL();
  
  isAnimating = NO;
  
  movementSpeed = 1000.0;
  rotationSpeed = 90.0;
  
	return self;
}

- (void) render {
//  NSLog(@"[TriVisRenderer render]");
  
  sceneWrapper->scene->render();
}

- (void) advanceTimeBy:(float)seconds {
  if (sceneWrapper->scene->movingLeft) sceneWrapper->scene->move(-seconds*movementSpeed*sceneWrapper->scene->scale, 0.0);
  if (sceneWrapper->scene->movingRight) sceneWrapper->scene->move(seconds*movementSpeed*sceneWrapper->scene->scale, 0.0);
  if (sceneWrapper->scene->movingDown) sceneWrapper->scene->move(0.0, seconds*movementSpeed*sceneWrapper->scene->scale);
  if (sceneWrapper->scene->movingUp) sceneWrapper->scene->move(0.0, -seconds*movementSpeed*sceneWrapper->scene->scale);
  if (sceneWrapper->scene->rotatingCW) sceneWrapper->scene->rotateBy(seconds*rotationSpeed);
  if (sceneWrapper->scene->rotatingCCW) sceneWrapper->scene->rotateBy(-seconds*rotationSpeed);
}

- (void) dealloc {
  NSLog(@"[TriVisRenderer dealloc]");
  
  delete sceneWrapper->scene;
}

- (void) moveX:(CGFloat)x andY:(CGFloat)y {
//  NSLog(@"[TriVisRenderer moveX:%f andY:%f]", x, y);
  sceneWrapper->scene->move(sceneWrapper->scene->scale*x, sceneWrapper->scene->scale*y);
}

- (void) scaleBy:(CGFloat)s {
  sceneWrapper->scene->scaleBy(s);
}

- (void) rotateBy:(CGFloat)degrees {
  sceneWrapper->scene->rotateBy(degrees);
}

- (void) center {
  sceneWrapper->scene->center();
}

- (void) viewMode:(unsigned int)mode {
  sceneWrapper->scene->showInput = false;
  sceneWrapper->scene->showTriangulation = false;
  sceneWrapper->scene->showTaggedTriangulation = false;
  sceneWrapper->scene->showOutput = false;
  
  switch (mode) {
    case 1:
      sceneWrapper->scene->showInput = true;
      break;
      
    case 2:
      sceneWrapper->scene->showTriangulation = true;
      break;
      
    case 3:
      sceneWrapper->scene->showTriangulation = true;
      sceneWrapper->scene->showTaggedTriangulation = true;
      break;
      
    case 4:
      sceneWrapper->scene->showTaggedTriangulation = true;
      sceneWrapper->scene->showOutput = true;
      break;
      
    default:
      break;
  }
}

- (void) movingLeft: (BOOL)ml {
  sceneWrapper->scene->movingLeft = ml;
  if (ml) isAnimating = YES;
  else if (!sceneWrapper->scene->needsToAnimate()) isAnimating = NO;
}

- (void) movingRight:(BOOL)mr {
  sceneWrapper->scene->movingRight = mr;
  if (mr) isAnimating = YES;
  else if (!sceneWrapper->scene->needsToAnimate()) isAnimating = NO;
}

- (void) movingDown:(BOOL)md {
  sceneWrapper->scene->movingDown = md;
  if (md) isAnimating = YES;
  else if (!sceneWrapper->scene->needsToAnimate()) isAnimating = NO;
}

- (void) movingUp:(BOOL)mu {
  sceneWrapper->scene->movingUp = mu;
  if (mu) isAnimating = YES;
  else if (!sceneWrapper->scene->needsToAnimate()) isAnimating = NO;
}

- (void) rotatingCW:(BOOL)rcw {
  sceneWrapper->scene->rotatingCW = rcw;
  if (rcw) isAnimating = YES;
  else if (!sceneWrapper->scene->needsToAnimate()) isAnimating = NO;
}

- (void) rotatingCCW:(BOOL)rccw {
  sceneWrapper->scene->rotatingCCW = rccw;
  if (rccw) isAnimating = YES;
  else if (!sceneWrapper->scene->needsToAnimate()) isAnimating = NO;
}

@end
