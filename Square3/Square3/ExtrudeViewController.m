//
//  ExtrudeViewController.m
//  Square3
//
//  Created on 4/27/15.
//

#import "ExtrudeViewController.h"
@import OpenGLES;

@interface ExtrudeViewController ()

@end

@implementation ExtrudeViewController 

- (void)viewDidLoad {
    [super viewDidLoad];

    // Extrusion gesture recognizer
    self.extrudeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(did2FingerPan:)];
  
    self.extrudeGestureRecognizer.minimumNumberOfTouches = 2;
    self.extrudeGestureRecognizer.maximumNumberOfTouches = 2;
    [self.view addGestureRecognizer: self.extrudeGestureRecognizer];

    self.sketchyRendering = YES;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.shapes = [[Data sharedData] fetchShapes];
    self.wireframeNodes = [[NSMutableArray alloc] initWithCapacity:self.shapes.count];
    self.shapeNodes = [[NSMutableArray alloc] initWithCapacity:self.shapes.count];
    
    [self sceneSetup];
    [self drawFlatShapes];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // animate the 2D "wall" becoming the "floor"
    if ([[Data sharedData] isFirstLoad]){
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          [SCNTransaction begin];
          [SCNTransaction setAnimationDuration:1];
          [self.cameraSphere setPosition:SCNVector3Make(0.0, 0.0, self.cameraSphere.position.z + 100)];
          [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x + M_PI_4, self.cameraSphere.eulerAngles.y - 0, self.cameraSphere.eulerAngles.z)];
          [SCNTransaction commit];
      });
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// modified from http://www.raywenderlich.com/83748/beginning-scene-kit-tutorial
- (void)sceneSetup {
    
    self.scene = [[SCNScene alloc] init];
    [self.sceneView setScene:self.scene];
    self.camera = [(Data*)[Data sharedData] camera];
  
    // camera sphere implementation from http://stackoverflow.com/a/25674762
    self.cameraSphere = [[SCNNode alloc] init];
    [self.cameraSphere addChildNode:self.camera];
    [self.scene.rootNode addChildNode:self.cameraSphere];
    
    [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x - M_PI_2, self.cameraSphere.eulerAngles.y - 0, self.cameraSphere.eulerAngles.z)];

    // add lighting
    SCNNode *ambientNode = [[SCNNode alloc] init];
    ambientNode.light = [[SCNLight alloc] init];
    ambientNode.light.type = SCNLightTypeAmbient;
    ambientNode.light.color = [UIColor colorWithWhite:0.67 alpha:1.0];
    [self.scene.rootNode addChildNode:ambientNode];
    
    SCNNode *omniNode = [[SCNNode alloc] init];
    omniNode.light = [[SCNLight alloc] init];
    omniNode.light.type = SCNLightTypeOmni;
    omniNode.light.color = [UIColor colorWithWhite:0.75 alpha:1.0];
    omniNode.position = SCNVector3Make(100.0, 400.0, 100.0);
    [self.scene.rootNode addChildNode:omniNode];

}

- (void)drawFlatShapes {
    
    self.wireframeNodes = [[NSMutableArray alloc] init];
    self.shapeNodes = [[NSMutableArray alloc] init];
    
    // draw a Plane that will represent the floor
    SCNGeometry *floorGeom = [SCNPlane planeWithWidth:[(Data *)[Data sharedData] screenWidth] height:[(Data *)[Data sharedData] screenHeight]];
    [floorGeom.firstMaterial.diffuse setContents:[UIColor whiteColor]];
    self.floor = [SCNNode nodeWithGeometry:floorGeom];
    
    for (Shape *shape in self.shapes) {
      
        if (!shape.extrusionDepth)
          shape.extrusionDepth = 1.0;
      
        UIBezierPath *path = [[UIBezierPath alloc] init];
        
        NSValue *firstValue = [shape.preferredRepresentation firstObject];
        CGPoint firstPoint = [firstValue CGPointValue];
        
        CGPoint flippedStart = CGPointMake(firstPoint.x, [(Data *)[Data sharedData] screenHeight] - firstPoint.y);
        [path moveToPoint:flippedStart];
        
        for (int i = 1; i < shape.preferredRepresentation.count; i++) {
            NSValue *val = [shape.preferredRepresentation objectAtIndex:i];
            CGPoint point = [val CGPointValue];
            
            // translate the coordinate system
            CGPoint newPoint = CGPointMake(point.x, [(Data *)[Data sharedData] screenHeight] - point.y);
            
            [path addLineToPoint:newPoint];
        }
        
        // naïvely close the shape
        [path closePath];
        [path setLineWidth:1.0];
        
        SCNGeometry *geom = [SCNShape shapeWithPath:path extrusionDepth:shape.extrusionDepth];
        
        
        if (!self.sketchyRendering) {
            // color the shape
            [geom.firstMaterial.diffuse setContents:shape.color];
            SCNNode *shapeToAdd = [SCNNode nodeWithGeometry:geom];
            
            // offset the node so the coordinates start in the bottom right of the "floor"
            shapeToAdd.position = SCNVector3Make(-([(Data *)[Data sharedData] screenWidth] / 2), -([(Data *)[Data sharedData] screenHeight] / 2), shape.extrusionDepth / 2);
            
            // add the shape to the floor
            [self.floor addChildNode:shapeToAdd];
            
            // add the shape to the array
            [self.shapeNodes addObject:shapeToAdd];
        } else {
            // color the shape white
            [geom.firstMaterial.diffuse setContents:[UIColor whiteColor]];
            SCNNode *whiteShapeToAdd = [SCNNode nodeWithGeometry:geom];
            [whiteShapeToAdd.geometry.firstMaterial setLightingModelName:SCNLightingModelConstant];
            
            // offset the node so the coordinates start in the bottom right of the "floor"
            whiteShapeToAdd.position = SCNVector3Make(-([(Data *)[Data sharedData] screenWidth] / 2), -([(Data *)[Data sharedData] screenHeight] / 2), shape.extrusionDepth / 2);
            
            // add the shape to the floor
            [self.floor addChildNode:whiteShapeToAdd];
            
            // add the node to the array
            [self.shapeNodes addObject:whiteShapeToAdd];

            // make the sketchy wireframe
            glLineWidth(2.0);
            SCNGeometry *wireframeGeometry = [self createWireframeShapeFromPoints:shape.preferredRepresentation withExtrusion:shape.extrusionDepth];
            SCNNode *wireframeToAdd = [SCNNode nodeWithGeometry:wireframeGeometry];
            
            // offset the node so the coordinates start in the bottom right of the "floor"
            wireframeToAdd.position = SCNVector3Make(-([(Data *)[Data sharedData] screenWidth] / 2), -([(Data *)[Data sharedData] screenHeight] / 2), 1.0);
            
            // add the shape to the floor
            [self.floor addChildNode:wireframeToAdd];
            
            // add the node to the array
            [self.wireframeNodes addObject:wireframeToAdd];

        }

    }
    
    // add the entire floor to the scene
    [self.scene.rootNode addChildNode:self.floor];
    
    // rotate the floor node so it's a floor and not a wall
    self.floor.rotation = SCNVector4Make(1.0, 0.0, 0.0, -(M_PI / 2));
}

// MARK: Custom Wireframe Generation
- (SCNGeometry *)createWireframeShapeFromPoints:(NSArray *)points withExtrusion:(CGFloat)extrusion {
    int c = (int)points.count;
    SCNVector3 vertices[c * 2];
    for (int i = 0; i < c; i++) {
        NSValue *val = [points objectAtIndex:i];
        CGPoint p = [val CGPointValue];
        
        // translate the coordinate system
        CGPoint newPoint = CGPointMake(p.x, [(Data *)[Data sharedData] screenHeight] - p.y);
        
        vertices[i] = SCNVector3Make(newPoint.x, newPoint.y, 0);
        vertices[c + i] = SCNVector3Make(newPoint.x, newPoint.y, extrusion);
    }
    SCNGeometrySource *geomSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:(c * 2)];
    
    
    // create the geometry element
    // an "element" is an array of *indeces* to connect
    int connections[c * 6];
    for (int i = 0; i < c; i++) {
        if (i == 0) {
            connections[0] = 0;
            connections[1] = 1;
            
            connections[c * 2] = c;
            connections[(c * 2) + 1] = c + 1;
            
            connections[c * 4] = 0;
            connections[(c * 4) + 1] = c;
        } else {
            // bottom face
            connections[i * 2] = i;
            connections[(i * 2) + 1] = i + 1;
            // top face
            connections[(c * 2) + (i * 2)] = c + i;
            connections[(c * 2) + (i * 2) + 1] = c + i + 1;
            // in-between
            connections[(c * 4) + (i * 2)] = i;
            connections[(c * 4) + (i * 2) + 1] = c + i;
        }
        
        
    }
    // fix two connections (close the shape on both faces)
    connections[(c * 2) - 1] = 0;
    connections[(c * 4) - 1] = c;
    
    
    NSData *data = [NSData dataWithBytes:connections length:sizeof(int) * c * 6];
    
    SCNGeometryElement *geomElement = [SCNGeometryElement geometryElementWithData:data primitiveType:SCNGeometryPrimitiveTypeLine primitiveCount:c * 6 bytesPerIndex:sizeof(int)];
    
    
    
    return [SCNGeometry geometryWithSources:@[geomSource] elements:@[geomElement]];
}

// MARK: Camera Control
- (IBAction)did1FingerPan:(UIPanGestureRecognizer *)sender {

    if (sender.state == UIGestureRecognizerStateBegan) {
        self.prevPosition = [sender translationInView:self.sceneView];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint newPosition = [sender translationInView:self.sceneView];
        float delX = newPosition.x - self.prevPosition.x;
        float delY = newPosition.y - self.prevPosition.y;
        
        if (self.cameraSphere.eulerAngles.x > -0.05 && delY < 0) { // too low
            [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x, self.cameraSphere.eulerAngles.y - (delX / 200), self.cameraSphere.eulerAngles.z)];
        } else if (self.cameraSphere.eulerAngles.x < -(M_PI_2) && delY > 0) {
            [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x, self.cameraSphere.eulerAngles.y - (delX / 200), self.cameraSphere.eulerAngles.z)];
        } else {
            [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x - (delY / 200), self.cameraSphere.eulerAngles.y - (delX / 200), self.cameraSphere.eulerAngles.z)];
        }
        
        self.prevPosition = newPosition;
    }

}



- (IBAction)didPinch:(UIPinchGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.prevScale = sender.scale;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        float del = sender.scale - self.prevScale;
        
        if (self.camera.position.z < 200.0 && del > 0) {
            return;
        } else {
            [self.camera setPosition:SCNVector3Make(self.camera.position.x, self.camera.position.y, self.camera.position.z - (del * 300))];
        }
        self.prevScale = sender.scale;
    }
}

// MARK: Extrusion
- (IBAction)did2FingerPan:(UIPanGestureRecognizer *)sender {
  
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"-----> Extrude Gesture");
        self.prevPosition = [sender translationInView:self.sceneView];
        NSArray *hits = [self.sceneView hitTest:[sender locationInView:self.sceneView] options:nil];
        if ([hits count] > 0) {
            
            if (self.sketchyRendering) {
                for (SCNHitTestResult *hit in hits) {
                    // make sure we get the shape node if we're sketchy rendering
                    if ([hit node] != self.floor && [hit node] != self.camera && [hit node] != self.cameraSphere && [[hit node].geometry isKindOfClass:[SCNShape class]]) {
                        self.extrudingNode = [hit node];
                        break;
                    }
                }
            } else {
                for (SCNHitTestResult *hit in hits) {
                    if ([hit node] != self.floor && [hit node] != self.camera && [hit node] != self.cameraSphere) {
                        self.extrudingNode = [hit node];
                        break;
                    }
                }
            }
            
            
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        
        if (self.sketchyRendering) {
            CGPoint newPosition = [sender translationInView:self.sceneView];
            float delY = newPosition.y - self.prevPosition.y;
            
            if (((SCNShape *)self.extrudingNode.geometry).extrusionDepth > 0.0 || delY < 0) {
                ((SCNShape *)self.extrudingNode.geometry).extrusionDepth -= delY;
                [self.extrudingNode setPosition:SCNVector3Make(self.extrudingNode.position.x, self.extrudingNode.position.y, self.extrudingNode.position.z - (delY * 0.5))];
            }
            
            // find the index of the node in the local array
            NSInteger index = [self.shapeNodes indexOfObject:self.extrudingNode];
            Shape *s = [self.shapes objectAtIndex:index];
            SCNNode *n = [self.wireframeNodes objectAtIndex:index];
            
            [n setGeometry:[self createWireframeShapeFromPoints:s.preferredRepresentation withExtrusion:((SCNShape *)self.extrudingNode.geometry).extrusionDepth]];
            
            self.currentExtrusionDepth -= delY;
            self.prevPosition = newPosition;
        } else {
            CGPoint newPosition = [sender translationInView:self.sceneView];
            float delY = newPosition.y - self.prevPosition.y;
            
            
            if (((SCNShape *)self.extrudingNode.geometry).extrusionDepth > 0.0 || delY < 0) {
                ((SCNShape *)self.extrudingNode.geometry).extrusionDepth -= delY;
                [self.extrudingNode setPosition:SCNVector3Make(self.extrudingNode.position.x, self.extrudingNode.position.y, self.extrudingNode.position.z - (delY * 0.5))];
            }
            self.currentExtrusionDepth -= delY;
            self.prevPosition = newPosition;
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        NSInteger index = [self.shapeNodes indexOfObject:self.extrudingNode];
        Shape *s = [[[Data sharedData] fetchShapes] objectAtIndex:index];
        s.extrusionDepth = self.currentExtrusionDepth / 2;
    }
}


- (IBAction)representationMethodChanged:(UISegmentedControl *)sender {
    
    // clear the stage
    for (SCNNode *n in self.floor.childNodes) {
        [n removeFromParentNode];
    }
    
    // redraw
    self.sketchyRendering = (sender.selectedSegmentIndex == 0);
    [self drawFlatShapes];
}



@end