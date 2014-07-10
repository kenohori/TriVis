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

#ifndef TriVis_TriVisScene_h
#define TriVis_TriVisScene_h

#include <iostream>
#include <vector>
#include <OpenGL/gl3.h>
#include <GLKit/GLKMath.h>

class TriVisScene {
public:
  GLKVector2 cameraPosition;
  GLfloat scale, angle;
  GLfloat width, height;
  
  GLKVector2 minBounds, maxBounds;
  GLKMatrix4 model, view, projection, mvp;
  
  GLuint vertexShader, fragmentShader, shaderProgram;
  GLint uniMVP;
  GLuint vboInput, vaoInput;
  GLuint vboTriangulation, vaoTriangulation;
  GLuint vboTaggedTriangulation, vaoTaggedTriangulation;
  GLuint vboOutput, vaoOutput;
  GLuint vboTest, vaoTest, eboTest;
  bool showInput, showTriangulation, showTaggedTriangulation, showOutput, showTest;
  
  TriVisScene();
  ~TriVisScene();
  
  void createVertexShader(const char *source);
  void createFragmentShader(const char *source);
  void initGL();
  
  void recomputeModelMatrix();
  void recomputeViewMatrix();
  void recomputeProjectionMatrix();
  void recomputeMVPMatrix();
  
  void loadInput(std::size_t numVertices, GLfloat *vertices);
  void loadTriangulation(std::size_t numVertices, GLfloat *vertices);
  void loadTaggedTriangulation(std::size_t numVertices, GLfloat *vertices);
  void loadOutput(std::size_t numVertices, GLfloat *vertices);
  void loadTestData();
  
  void resize(GLfloat width, GLfloat height);
  
  void move(float x, float y);
  void scaleBy(float s);
  void rotateBy(float degrees);
  void center();
  
  void moveTo(float x, float y);
  void render();
  
  bool needsToAnimate();
  
  bool movingUp, movingDown, movingLeft, movingRight, rotatingCW, rotatingCCW;
};

#endif
