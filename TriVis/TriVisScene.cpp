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

#include "TriVisScene.h"

TriVisScene::TriVisScene() {
  std::cout << "TriVisScene::TriVisScene()" << std::endl;
  
  width = 800;
  height = 600;
  
  cameraPosition = GLKVector2Make(0.0, 0.0);
  angle = 0.0;
  scale = 0.001;
  
  recomputeModelMatrix();
  recomputeViewMatrix();
  recomputeProjectionMatrix();
  
  movingLeft = false;
  movingRight = false;
  movingUp = false;
  movingDown = false;
  rotatingCCW = false;
  rotatingCW = false;
  
  showTest = true;
  showInput = false;
  showTriangulation = false;
  showTaggedTriangulation = false;
  showOutput = false;
}

TriVisScene::~TriVisScene() {
  std::cout << "TriVisScene::~TriVisScene()" << std::endl;
  
  glDeleteProgram(shaderProgram);
  glDeleteShader(fragmentShader);
  glDeleteShader(vertexShader);
  
  glDeleteBuffers(1, &vboTest);
  glDeleteVertexArrays(1, &vaoTest);
  glDeleteBuffers(1, &eboTest);
  
  glDeleteBuffers(1, &vboInput);
  glDeleteVertexArrays(1, &vaoInput);
  
  glDeleteBuffers(1, &vboTriangulation);
  glDeleteVertexArrays(1, &vaoTriangulation);
  
  glDeleteBuffers(1, &vboTaggedTriangulation);
  glDeleteVertexArrays(1, &vaoTaggedTriangulation);
  
  glDeleteBuffers(1, &vboOutput);
  glDeleteVertexArrays(1, &vaoOutput);
}

void TriVisScene::createVertexShader(const char *source) {
  std::cout << "TriVisScene::createVertexShader()" << std::endl;
  
  vertexShader = glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vertexShader, 1, &source, NULL);
  glCompileShader(vertexShader);
  GLint status;
  glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
  if (status == GL_TRUE) {
    std::cout << "Vertex shader ok" << std::endl;
  } else {
    char buffer[1024];
    glGetShaderInfoLog(vertexShader, 1024, NULL, buffer);
    std::cerr << "Vertex shader error: " << std::endl << buffer << std::endl;
  }
}

void TriVisScene::createFragmentShader(const char *source) {
  std::cout << "TriVisScene::createFragmentShader()" << std::endl;
  
  fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragmentShader, 1, &source, NULL);
  glCompileShader(fragmentShader);
  GLint status;
  glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &status);
  if (status == GL_TRUE) {
    std::cout << "Fragment shader ok" << std::endl;
  } else {
    char buffer[1024];
    glGetShaderInfoLog(fragmentShader, 1024, NULL, buffer);
    std::cerr << "Fragment shader error: " << std::endl << buffer << std::endl;
  }
}

void TriVisScene::initGL() {
  std::cout << "TriVisScene::initGL()" << std::endl;
  
  // Link the vertex and fragment shader into a shader program
  shaderProgram = glCreateProgram();
  glAttachShader(shaderProgram, vertexShader);
  glAttachShader(shaderProgram, fragmentShader);
  glBindFragDataLocation(shaderProgram, 0, "outColor");
  glLinkProgram(shaderProgram);
  glUseProgram(shaderProgram);
  
  // Get the matrices and put the current values
  uniMVP = glGetUniformLocation(shaderProgram, "mvp");
  glUniformMatrix4fv(uniMVP, 1, GL_FALSE, mvp.m);
  
  // Create objects for test
  glGenVertexArrays(1, &vaoTest);
  glGenBuffers(1, &vboTest);
  glGenBuffers(1, &eboTest);
  
  // Create objects for input
  glGenVertexArrays(1, &vaoInput);
  glGenBuffers(1, &vboInput);
  
  // Create objects for triangulation
  glGenVertexArrays(1, &vaoTriangulation);
  glGenBuffers(1, &vboTriangulation);
  
  // Create objects for tagged triangulation
  glGenVertexArrays(1, &vaoTaggedTriangulation);
  glGenBuffers(1, &vboTaggedTriangulation);
  
  // Create objects for output
  glGenVertexArrays(1, &vaoOutput);
  glGenBuffers(1, &vboOutput);
  
  loadTestData();
}

void TriVisScene::recomputeModelMatrix() {
  model = GLKMatrix4MakeTranslation((minBounds.v[0]+maxBounds.v[0])/2.0, (minBounds.v[1]+maxBounds.v[1])/2.0, 0.0);
  model = GLKMatrix4RotateZ(model, angle/57.29577951308233);
  model = GLKMatrix4Translate(model, -(minBounds.v[0]+maxBounds.v[0])/2.0, -(minBounds.v[1]+maxBounds.v[1])/2.0, 0.0);
  recomputeMVPMatrix();
}

void TriVisScene::recomputeViewMatrix() {
  view = GLKMatrix4MakeLookAt(cameraPosition.v[0], cameraPosition.v[1], 0.0, cameraPosition.v[0], cameraPosition.v[1], 1.0, 0.0, 1.0, 0.0);
  recomputeMVPMatrix();
}

void TriVisScene::recomputeProjectionMatrix() {
  projection = GLKMatrix4MakeOrtho(-width*scale, width*scale, -height*scale, height*scale, -10.0, 10.0);
  recomputeMVPMatrix();
}

void TriVisScene::recomputeMVPMatrix() {
  mvp = GLKMatrix4Multiply(projection, GLKMatrix4Multiply(view, model));
}

void TriVisScene::loadInput(std::size_t numVertices, GLfloat *vertices) {
  std::cout << "Loading " << numVertices << " input vertices..." << std::endl;
  glBindBuffer(GL_ARRAY_BUFFER, vboInput);
  glBufferData(GL_ARRAY_BUFFER, numVertices*sizeof(GLfloat), vertices, GL_STATIC_DRAW);
  
  glBindVertexArray(vaoInput);
  
  // Specify the layout of the vertex data
  GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
  glEnableVertexAttribArray(posAttrib);
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), 0);
  GLint colAttrib = glGetAttribLocation(shaderProgram, "color");
  glEnableVertexAttribArray(colAttrib);
  glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), (void *)(2*sizeof(float)));
  
  maxBounds = minBounds = GLKVector2Make(vertices[0], vertices[1]);
  for (std::size_t currentVertex = 1; currentVertex < numVertices/5; ++currentVertex) {
    if (vertices[5*currentVertex+0] < minBounds.v[0]) minBounds.v[0] = vertices[5*currentVertex+0];
    if (vertices[5*currentVertex+1] < minBounds.v[1]) minBounds.v[1] = vertices[5*currentVertex+1];
    if (vertices[5*currentVertex+0] > maxBounds.v[0]) maxBounds.v[0] = vertices[5*currentVertex+0];
    if (vertices[5*currentVertex+1] > maxBounds.v[1]) maxBounds.v[1] = vertices[5*currentVertex+1];
  } std::cout << "Bounds: Min(" << minBounds.v[0] << ", " << minBounds.v[1] << ") Max(" << maxBounds.v[0] << ", " << maxBounds.v[1] << ")" << std::endl;
  
  showTest = false;
  showInput = true;
}

void TriVisScene::loadTriangulation(std::size_t numVertices, GLfloat *vertices) {
  std::cout << "Loading " << numVertices << " triangulation vertices..." << std::endl;
  glBindBuffer(GL_ARRAY_BUFFER, vboTriangulation);
  glBufferData(GL_ARRAY_BUFFER, numVertices*sizeof(GLfloat), vertices, GL_STATIC_DRAW);
  
  glBindVertexArray(vaoTriangulation);
  
  // Specify the layout of the vertex data
  GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
  glEnableVertexAttribArray(posAttrib);
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), 0);
  GLint colAttrib = glGetAttribLocation(shaderProgram, "color");
  glEnableVertexAttribArray(colAttrib);
  glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), (void *)(2*sizeof(float)));
}

void TriVisScene::loadTaggedTriangulation(std::size_t numVertices, GLfloat *vertices) {
  std::cout << "Loading " << numVertices << " tagged triangulation vertices..." << std::endl;
  glBindBuffer(GL_ARRAY_BUFFER, vboTaggedTriangulation);
  glBufferData(GL_ARRAY_BUFFER, numVertices*sizeof(GLfloat), vertices, GL_STATIC_DRAW);
  
  glBindVertexArray(vaoTaggedTriangulation);
  
  // Specify the layout of the vertex data
  GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
  glEnableVertexAttribArray(posAttrib);
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), 0);
  GLint colAttrib = glGetAttribLocation(shaderProgram, "color");
  glEnableVertexAttribArray(colAttrib);
  glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), (void *)(2*sizeof(float)));
}

void TriVisScene::loadOutput(std::size_t numVertices, GLfloat *vertices) {
  std::cout << "Loading " << numVertices << " output vertices..." << std::endl;
  glBindBuffer(GL_ARRAY_BUFFER, vboOutput);
  glBufferData(GL_ARRAY_BUFFER, numVertices*sizeof(GLfloat), vertices, GL_STATIC_DRAW);
  
  glBindVertexArray(vaoOutput);
  
  // Specify the layout of the vertex data
  GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
  glEnableVertexAttribArray(posAttrib);
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), 0);
  GLint colAttrib = glGetAttribLocation(shaderProgram, "color");
  glEnableVertexAttribArray(colAttrib);
  glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), (void *)(2*sizeof(float)));
}

void TriVisScene::loadTestData() {
  
  minBounds = GLKVector2Make(-0.5f, -0.5f);
  maxBounds = GLKVector2Make(0.5f, 0.5f);
  
  GLfloat vertices[] = {
    -0.5f,  0.5f, 1.0f, 0.0f, 0.0f, // Top-left
    0.5f,  0.5f, 0.0f, 1.0f, 0.0f, // Top-right
    0.5f, -0.5f, 0.0f, 0.0f, 1.0f, // Bottom-right
    -0.5f, -0.5f, 1.0f, 1.0f, 1.0f  // Bottom-left
  };
  
  glBindBuffer(GL_ARRAY_BUFFER, vboTest);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  
  GLuint elements[] = {
    0, 1, 2,
    2, 3, 0
  };
  
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eboTest);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(elements), elements, GL_STATIC_DRAW);
  
  glBindVertexArray(vaoTest);
  
  // Specify the layout of the vertex data
  GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
  glEnableVertexAttribArray(posAttrib);
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), 0);
  GLint colAttrib = glGetAttribLocation(shaderProgram, "color");
  glEnableVertexAttribArray(colAttrib);
  glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
                        5*sizeof(float), (void *)(2*sizeof(float)));
  
}

void TriVisScene::resize(GLfloat width, GLfloat height) {
//  std::cout << "TriVisScene::resize(" << width << ", " << height << ")" << std::endl;
  this->width = width;
  this->height = height;
  recomputeProjectionMatrix();
  glUniformMatrix4fv(uniMVP, 1, GL_FALSE, mvp.m);
  glViewport(0, 0, width, height);
}

void TriVisScene::move(float x, float y) {
//  std::cout << "TriVisScene::move(" << x << ", " << y << ")" << std::endl;
  if (x == 0.0 && y == 0.0) return;
  moveTo(this->cameraPosition.v[0]+x, this->cameraPosition.v[1]+y);
}

void TriVisScene::scaleBy(float s) {
//  std::cout << "TriVisScene::scaleBy(" << s << ")" << std::endl;
  if (s == 1.0) return;
  this->scale *= s;
  recomputeProjectionMatrix();
  glUniformMatrix4fv(uniMVP, 1, GL_FALSE, mvp.m);
}

void TriVisScene::rotateBy(float degrees) {
//  std::cout << "TriVisScene::rotateBy(" << degrees << ")" << std::endl;
  angle += degrees;
  recomputeModelMatrix();
  glUniformMatrix4fv(uniMVP, 1, GL_FALSE, mvp.m);
}

void TriVisScene::center() {
  angle = 0.0;
  recomputeModelMatrix();
  
  this->cameraPosition.v[0] = (minBounds.v[0]+maxBounds.v[0])/2.0;
  this->cameraPosition.v[1] = (minBounds.v[1]+maxBounds.v[1])/2.0;
  recomputeViewMatrix();
  
  GLfloat maxScaleX = (maxBounds.v[0]-minBounds.v[0])/width;
  GLfloat maxScaleY = (maxBounds.v[1]-minBounds.v[1])/height;
//  std::cout << "Current scale: " << scale << std::endl;
//  std::cout << "Max scales: X=" << maxScaleX << " Y=" << maxScaleY << std::endl;
  if (maxScaleX > maxScaleY) {
    this->scale = maxScaleX/1.8;
  } else {
    this->scale = maxScaleY/1.8;
  } recomputeProjectionMatrix();
  glUniformMatrix4fv(uniMVP, 1, GL_FALSE, mvp.m);
}

void TriVisScene::moveTo(float x, float y) {
//  std::cout << "TriVisScene::moveTo()" << std::endl;
  this->cameraPosition = GLKVector2Make(x, y);
  recomputeViewMatrix();
  glUniformMatrix4fv(uniMVP, 1, GL_FALSE, mvp.m);
}

void TriVisScene::render() {
//  std::cout << "TriVisScene::render()" << std::endl;
  
  glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  
  if (showTest) {
    glBindVertexArray(vaoTest);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eboTest);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
  }
  
  if (showInput) {
    glBindBuffer(GL_ARRAY_BUFFER, vboInput);
    glBindVertexArray(vaoInput);
    int size;
    glGetBufferParameteriv(GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);
    glDrawArrays(GL_LINES, 0, size/sizeof(GLfloat));
  }
  
  if (showTaggedTriangulation) {
    glBindBuffer(GL_ARRAY_BUFFER, vboTaggedTriangulation);
    glBindVertexArray(vaoTaggedTriangulation);
    int size;
    glGetBufferParameteriv(GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);
    glDrawArrays(GL_TRIANGLES, 0, size/sizeof(GLfloat));
  }
  
  if (showTriangulation) {
    glBindBuffer(GL_ARRAY_BUFFER, vboTriangulation);
    glBindVertexArray(vaoTriangulation);
    int size;
    glGetBufferParameteriv(GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);
    glDrawArrays(GL_LINES, 0, size/sizeof(GLfloat));
  }
  
  if (showOutput) {
    glBindBuffer(GL_ARRAY_BUFFER, vboOutput);
    glBindVertexArray(vaoOutput);
    int size;
    glGetBufferParameteriv(GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);
    glDrawArrays(GL_LINES, 0, size/sizeof(GLfloat));
  }
}

bool TriVisScene::needsToAnimate() {
  return (movingLeft||movingRight||movingDown||movingUp||rotatingCW||rotatingCCW);
}