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

#import "TriVisWindowController.h"

#import "Polygon_repair.h"

struct Polygon_repairWrapper {
  Polygon_repair *prepair;
};

@implementation TriVisWindowController

- (id)initWithWindow:(NSWindow *)window {
  
  self = [super initWithWindow:window];
  
  if (self) {
		// Initialize to nil since it indicates app is not fullscreen
		fullscreenWindow = nil;
    
    scrollingSensitivity = 5.0;
    rotationSensitivity = 2.0;
    
    prepairWrapper = new Polygon_repairWrapper();
    prepairWrapper->prepair = new Polygon_repair();
  }
  
  return self;
}

- (void) goFullscreen {
  
  // If app is already fullscreen...
	if (fullscreenWindow) {
		//...don't do anything
		return;
	}
  
  // Allocate a new fullscreen window
	fullscreenWindow = [[TriVisFullscreenWindow alloc] init];
  
	// Resize the view to screensize
	NSRect viewRect = [fullscreenWindow frame];
  
	// Set the view to the size of the fullscreen window
	[view setFrameSize: viewRect.size];
  
	// Set the view in the fullscreen window
	[fullscreenWindow setContentView:view];
  
	standardWindow = [self window];
  
	// Hide non-fullscreen window so it doesn't show up when switching out
	// of this app (i.e. with CMD-TAB)
	[standardWindow orderOut:self];
  
	// Set controller to the fullscreen window so that all input will go to
	// this controller (self)
	[self setWindow:fullscreenWindow];
  
	// Show the window and make it the key window for input
	[fullscreenWindow makeKeyAndOrderFront:self];
}

- (void) goWindow {
  
  // If controller doesn't have a full screen window...
	if(fullscreenWindow == nil)
	{
		//...app is already windowed so don't do anything
		return;
	}
  
	// Get the rectangle of the original window
	NSRect viewRect = [standardWindow frame];
	
	// Set the view rect to the new size
	[view setFrame:viewRect];
  
	// Set controller to the standard window so that all input will go to
	// this controller (self)
	[self setWindow:standardWindow];
  
	// Set the content of the orginal window to the view
	[[self window] setContentView:view];
  
	// Show the window and make it the key window for input
	[[self window] makeKeyAndOrderFront:self];
  
	// Ensure we set fullscreen Window to nil so our checks for
	// windowed vs. fullscreen mode elsewhere are correct
	fullscreenWindow = nil;
}

- (void) keyDown:(NSEvent *)event {
  
  unichar c = [event keyCode];
  
  NSLog(@"Pressed: %i", c);
  
  switch (c) {
    
      // [F/f] toggles full-screen mode
    case 3:
			if(fullscreenWindow == nil) {
				[self goFullscreen];
			} else {
				[self goWindow];
			} return;
      
      // [C/c] center data on screen
    case 8:
      [view->renderer center];
      [view drawView];
      break;
      
      // [1-4] set view mode
    case 18:
    case 19:
    case 20:
    case 21:
      [view->renderer viewMode:c-17];
      [view drawView];
      break;
      
      // [O/o] open file
    case 31:
      if (fullscreenWindow != nil) {
				[self goWindow];
			} [self openFile:self];
      break;
      
      // [</,] rotate CCW
    case 43:
      [self startAnimation];
      [view->renderer rotatingCCW:true];
      break;
      
      // [>/.] rotate CW
    case 47:
      [self startAnimation];
      [view->renderer rotatingCW:true];
      break;
      
      // [Esc] closes full-screen mode
		case 53:
			if (fullscreenWindow != nil) {
				[self goWindow];
			} return;
      
      // [Left] go left
    case 123:
      [self startAnimation];
      [view->renderer movingLeft:true];
      break;
      
      // [Right] go right
    case 124:
      [self startAnimation];
      [view->renderer movingRight:true];
      break;
      
      // [Down] go down
    case 125:
      [self startAnimation];
      [view->renderer movingDown:true];
      break;
      
      // [Up] go up
    case 126:
      [self startAnimation];
      [view->renderer movingUp:true];
      break;
      
      // Allow other characters to be handled (or not and beep)
    default:
      [super keyDown:event];
      break;
  }
}

- (void) keyUp:(NSEvent *)event {
  
  unichar c = [event keyCode];
  
  switch (c) {
      
      // [</,] stop rotating CCW
    case 43:
      [view->renderer rotatingCCW:false];
      [self stopAnimation];
      break;
      
      // [>/.] stop rotating CW
    case 47:
      [view->renderer rotatingCW:false];
      [self stopAnimation];
      break;
      
      // [Left] stop going left
    case 123:
      [view->renderer movingLeft:false];
      [self stopAnimation];
      break;
      
      // [Right] stop going right
    case 124:
      [view->renderer movingRight:false];
      [self stopAnimation];
      break;
      
      // [Down] stop going down
    case 125:
      [view->renderer movingDown:false];
      [self stopAnimation];
      break;
      
      // [Up] stop going up
    case 126:
      // Up
      [view->renderer movingUp:false];
      [self stopAnimation];
      break;
      
      // Allow other characters to be handled (or not and beep)
    default:
      [super keyUp:event];
      break;
  }
}

- (void) scrollWheel:(NSEvent *)event {
  [view->renderer moveX:scrollingSensitivity*[event scrollingDeltaX] andY:scrollingSensitivity*[event scrollingDeltaY]];
  [view drawView];
}

- (void) magnifyWithEvent:(NSEvent *)event {
  [view->renderer scaleBy:1.0-[event magnification]];
  [view drawView];
}

- (void) rotateWithEvent:(NSEvent *)event {
  [view->renderer rotateBy:-rotationSensitivity*[event rotation]];
  [view drawView];
}

- (void) startAnimation {
	if (!view->renderer->isAnimating) {
    view->renderer->renderTime = CFAbsoluteTimeGetCurrent();
    CVDisplayLinkStart(view->displayLink);
	}
}

- (void) stopAnimation {
	if (!view->renderer->isAnimating) {
		CVDisplayLinkStop(view->displayLink);
	}
}

- (IBAction) openFile:(id)sender {
  NSArray *fileTypes = [NSArray arrayWithObjects:@"shp", @"geojson", @"txt", nil];
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseFiles:YES];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setAllowedFileTypes:fileTypes];
  
  [openPanel beginSheetModalForWindow:standardWindow completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSFileHandlingPanelOKButton) {
      NSArray *urls = [openPanel URLs];
      NSString *filename = [[urls objectAtIndex:0] path];
//      NSLog(@"Opening %@", filename);
      
      OGRRegisterAll();
      OGRGeometry *inGeometry, *outGeometry;
      OGRDataSource *dataSource;
      OGRLayer *dataLayer;
      OGRFeature *feature;
      
      if ([filename hasSuffix:@".txt"]) {
        NSStringEncoding *encoding = nullptr;
        NSString *fileContents = [NSString stringWithContentsOfFile:filename usedEncoding:encoding error:NULL];
        char *cstr = new char[[fileContents length]+1];
        std::strcpy(cstr, [fileContents UTF8String]);
//        std::cout << "WKT: " << cstr;
        OGRGeometryFactory::createFromWkt(&cstr, NULL, &inGeometry);
      }
      
      else {
        dataSource = OGRSFDriverRegistrar::Open([filename UTF8String], false);
        if (dataSource == NULL) {
          NSLog(@"Error: Could not open file");
          return;
        } dataLayer = dataSource->GetLayer(0);
        dataLayer->ResetReading();
        feature = dataLayer->GetNextFeature();
        if (feature->GetGeometryRef()->getGeometryType() == wkbPolygon ||
            feature->GetGeometryRef()->getGeometryType() == wkbMultiPolygon) {
          inGeometry = feature->GetGeometryRef();
        } else {
          NSLog(@"Error: Feature is not a polygon or multipolygon");
          return;
        }
      }
      
//      char *input_wkt;
//      inGeometry->exportToWkt(&input_wkt);
//      NSLog(@"Input polygon: %s", input_wkt);
      
      std::vector<GLfloat> inputVertices;
      if (inGeometry->getGeometryType() == wkbPolygon) {
        OGRPolygon *polygon = static_cast<OGRPolygon *>(inGeometry);

        for (int currentVertex = 0; currentVertex < polygon->getExteriorRing()->getNumPoints(); ++currentVertex) {
          inputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex));
          inputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex));
          inputVertices.push_back(0.0);
          inputVertices.push_back(0.0);
          inputVertices.push_back(0.0);
          if (currentVertex+1 < polygon->getExteriorRing()->getNumPoints()) {
            inputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex+1));
            inputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex+1));
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
          } else {
            inputVertices.push_back(polygon->getExteriorRing()->getX(0));
            inputVertices.push_back(polygon->getExteriorRing()->getY(0));
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
          }
        }
        for (int currentRing = 0; currentRing < polygon->getNumInteriorRings(); ++currentRing) {
          for (int currentVertex = 0; currentVertex < polygon->getInteriorRing(currentRing)->getNumPoints(); ++currentVertex) {
            inputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex));
            inputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex));
            inputVertices.push_back(1.0);
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
            if (currentVertex+1 < polygon->getInteriorRing(currentRing)->getNumPoints()) {
              inputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex+1));
              inputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex+1));
              inputVertices.push_back(1.0);
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
            } else {
              inputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(0));
              inputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(0));
              inputVertices.push_back(1.0);
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
            }
          }
        }
      } else if (inGeometry->getGeometryType() == wkbMultiPolygon) {
        OGRMultiPolygon *multipolygon = static_cast<OGRMultiPolygon *>(inGeometry);
        
        for (int current_polygon = 0; current_polygon < multipolygon->getNumGeometries(); ++current_polygon) {
          OGRPolygon *polygon = static_cast<OGRPolygon *>(multipolygon->getGeometryRef(current_polygon));
          
          for (int currentVertex = 0; currentVertex < polygon->getExteriorRing()->getNumPoints(); ++currentVertex) {
            inputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex));
            inputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex));
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
            inputVertices.push_back(0.0);
            if (currentVertex+1 < polygon->getExteriorRing()->getNumPoints()) {
              inputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex+1));
              inputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex+1));
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
            } else {
              inputVertices.push_back(polygon->getExteriorRing()->getX(0));
              inputVertices.push_back(polygon->getExteriorRing()->getY(0));
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
            }
          }
          for (int currentRing = 0; currentRing < polygon->getNumInteriorRings(); ++currentRing) {
            for (int currentVertex = 0; currentVertex < polygon->getInteriorRing(currentRing)->getNumPoints(); ++currentVertex) {
              inputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex));
              inputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex));
              inputVertices.push_back(1.0);
              inputVertices.push_back(0.0);
              inputVertices.push_back(0.0);
              if (currentVertex+1 < polygon->getInteriorRing(currentRing)->getNumPoints()) {
                inputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex+1));
                inputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex+1));
                inputVertices.push_back(1.0);
                inputVertices.push_back(0.0);
                inputVertices.push_back(0.0);
              } else {
                inputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(0));
                inputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(0));
                inputVertices.push_back(1.0);
                inputVertices.push_back(0.0);
                inputVertices.push_back(0.0);
              }
            }
          }
        }
      }
      
//      for (unsigned int currentVertex = 0; currentVertex < vertices.size(); ++currentVertex) {
//        std::cout << vertices[currentVertex] << " ";
//        if (currentVertex % 5 == 4) std::cout << std::endl;
//      }
      
      [view->renderer loadInput:inputVertices.size() vertices:inputVertices.data()];
      
      if (![filename hasSuffix:@".txt"]) {
        OGRFeature::DestroyFeature(feature);
        OGRDataSource::DestroyDataSource(dataSource);
      }
      
      prepairWrapper->prepair->insert_constraints(inGeometry);
      prepairWrapper->prepair->attempt_to_fix_overlapping_constraints();
      
      std::vector<GLfloat> triangulationVertices;
      for (prepair::Triangulation::Finite_edges_iterator current_edge = prepairWrapper->prepair->triangulation.finite_edges_begin(); current_edge != prepairWrapper->prepair->triangulation.finite_edges_end(); ++current_edge) {
        triangulationVertices.push_back(CGAL::to_double(current_edge->first->vertex(prepair::Triangulation::cw(current_edge->second))->point().x()));
        triangulationVertices.push_back(CGAL::to_double(current_edge->first->vertex(prepair::Triangulation::cw(current_edge->second))->point().y()));
        if (prepairWrapper->prepair->triangulation.is_constrained(*current_edge)) {
          triangulationVertices.push_back(0.0);
          triangulationVertices.push_back(0.0);
          triangulationVertices.push_back(0.0);
        } else {
          triangulationVertices.push_back(0.7);
          triangulationVertices.push_back(0.7);
          triangulationVertices.push_back(0.7);
        }
        
        triangulationVertices.push_back(CGAL::to_double(current_edge->first->vertex(prepair::Triangulation::ccw(current_edge->second))->point().x()));
        triangulationVertices.push_back(CGAL::to_double(current_edge->first->vertex(prepair::Triangulation::ccw(current_edge->second))->point().y()));
        if (prepairWrapper->prepair->triangulation.is_constrained(*current_edge)) {
          triangulationVertices.push_back(0.0);
          triangulationVertices.push_back(0.0);
          triangulationVertices.push_back(0.0);
        } else {
          triangulationVertices.push_back(0.7);
          triangulationVertices.push_back(0.7);
          triangulationVertices.push_back(0.7);
        }
      }
      
      [view->renderer loadTriangulation:triangulationVertices.size() vertices:triangulationVertices.data()];
      
      prepairWrapper->prepair->tag_odd_even();
      
      std::vector<GLfloat> taggedTriangulationVertices;
      for (prepair::Triangulation::Finite_faces_iterator current_face = prepairWrapper->prepair->triangulation.finite_faces_begin(); current_face != prepairWrapper->prepair->triangulation.finite_faces_end(); ++current_face) {
        if (current_face->info().is_in_interior()) {
          taggedTriangulationVertices.push_back(CGAL::to_double(current_face->vertex(0)->point().x()));
          taggedTriangulationVertices.push_back(CGAL::to_double(current_face->vertex(0)->point().y()));
          taggedTriangulationVertices.push_back(1.0);
          taggedTriangulationVertices.push_back(1.0);
          taggedTriangulationVertices.push_back(0.0);
          taggedTriangulationVertices.push_back(CGAL::to_double(current_face->vertex(1)->point().x()));
          taggedTriangulationVertices.push_back(CGAL::to_double(current_face->vertex(1)->point().y()));
          taggedTriangulationVertices.push_back(1.0);
          taggedTriangulationVertices.push_back(1.0);
          taggedTriangulationVertices.push_back(0.0);
          taggedTriangulationVertices.push_back(CGAL::to_double(current_face->vertex(2)->point().x()));
          taggedTriangulationVertices.push_back(CGAL::to_double(current_face->vertex(2)->point().y()));
          taggedTriangulationVertices.push_back(1.0);
          taggedTriangulationVertices.push_back(1.0);
          taggedTriangulationVertices.push_back(0.0);
        }
      }
      
      [view->renderer loadTaggedTriangulation:taggedTriangulationVertices.size() vertices:taggedTriangulationVertices.data()];
      
      outGeometry = prepairWrapper->prepair->reconstruct();
      
      std::vector<GLfloat> outputVertices;
      if (outGeometry->getGeometryType() == wkbPolygon) {
        OGRPolygon *polygon = static_cast<OGRPolygon *>(outGeometry);
        
        for (int currentVertex = 0; currentVertex < polygon->getExteriorRing()->getNumPoints(); ++currentVertex) {
          outputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex));
          outputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex));
          outputVertices.push_back(0.0);
          outputVertices.push_back(0.0);
          outputVertices.push_back(0.0);
          if (currentVertex+1 < polygon->getExteriorRing()->getNumPoints()) {
            outputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex+1));
            outputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex+1));
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
          } else {
            outputVertices.push_back(polygon->getExteriorRing()->getX(0));
            outputVertices.push_back(polygon->getExteriorRing()->getY(0));
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
          }
        }
        for (int currentRing = 0; currentRing < polygon->getNumInteriorRings(); ++currentRing) {
          for (int currentVertex = 0; currentVertex < polygon->getInteriorRing(currentRing)->getNumPoints(); ++currentVertex) {
            outputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex));
            outputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex));
            outputVertices.push_back(1.0);
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
            if (currentVertex+1 < polygon->getInteriorRing(currentRing)->getNumPoints()) {
              outputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex+1));
              outputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex+1));
              outputVertices.push_back(1.0);
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
            } else {
              outputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(0));
              outputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(0));
              outputVertices.push_back(1.0);
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
            }
          }
        }
      } else if (outGeometry->getGeometryType() == wkbMultiPolygon) {
        OGRMultiPolygon *multipolygon = static_cast<OGRMultiPolygon *>(inGeometry);
        
        for (int current_polygon = 0; current_polygon < multipolygon->getNumGeometries(); ++current_polygon) {
          OGRPolygon *polygon = static_cast<OGRPolygon *>(multipolygon->getGeometryRef(current_polygon));
          
          for (int currentVertex = 0; currentVertex < polygon->getExteriorRing()->getNumPoints(); ++currentVertex) {
            outputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex));
            outputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex));
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
            outputVertices.push_back(0.0);
            if (currentVertex+1 < polygon->getExteriorRing()->getNumPoints()) {
              outputVertices.push_back(polygon->getExteriorRing()->getX(currentVertex+1));
              outputVertices.push_back(polygon->getExteriorRing()->getY(currentVertex+1));
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
            } else {
              outputVertices.push_back(polygon->getExteriorRing()->getX(0));
              outputVertices.push_back(polygon->getExteriorRing()->getY(0));
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
            }
          }
          for (int currentRing = 0; currentRing < polygon->getNumInteriorRings(); ++currentRing) {
            for (int currentVertex = 0; currentVertex < polygon->getInteriorRing(currentRing)->getNumPoints(); ++currentVertex) {
              outputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex));
              outputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex));
              outputVertices.push_back(1.0);
              outputVertices.push_back(0.0);
              outputVertices.push_back(0.0);
              if (currentVertex+1 < polygon->getInteriorRing(currentRing)->getNumPoints()) {
                outputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(currentVertex+1));
                outputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(currentVertex+1));
                outputVertices.push_back(1.0);
                outputVertices.push_back(0.0);
                outputVertices.push_back(0.0);
              } else {
                outputVertices.push_back(polygon->getInteriorRing(currentRing)->getX(0));
                outputVertices.push_back(polygon->getInteriorRing(currentRing)->getY(0));
                outputVertices.push_back(1.0);
                outputVertices.push_back(0.0);
                outputVertices.push_back(0.0);
              }
            }
          }
        }
      }
      
      [view->renderer loadOutput:outputVertices.size() vertices:outputVertices.data()];
      
      [view->renderer center];
    }
  }];
}

@end
