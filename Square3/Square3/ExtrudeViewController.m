//
//  ExtrudeViewController.m
//  Square3
//
//  Created on 4/27/15.
//

#import "ExtrudeViewController.h"

@interface ExtrudeViewController ()

@end

@implementation ExtrudeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self sceneSetup];
    [self drawFlatShapes];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // animate the 2D "wall" becoming the "floor"
    // delay 1 second
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:2];
        [self.cameraSphere setPosition:SCNVector3Make(0.0, 0.0, self.cameraSphere.position.z + 100)];
        [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x + M_PI_4, self.cameraSphere.eulerAngles.y - 0, self.cameraSphere.eulerAngles.z)];
        [SCNTransaction commit];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// modified from http://www.raywenderlich.com/83748/beginning-scene-kit-tutorial
- (void)sceneSetup {
    
    self.scene = [[SCNScene alloc] init];
    [self.sceneView setScene:self.scene];
    
    SCNCamera *cam = [[SCNCamera alloc] init];
    cam.automaticallyAdjustsZRange = YES;
    cam.usesOrthographicProjection = NO;
    
    float distance = 530.0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        distance = 800.0;
    }
    
    self.camera = [[SCNNode alloc] init];
    [self.camera setCamera:cam];
    [self.camera setPosition:SCNVector3Make(0.0, 0.0, distance)];
    
    // camera sphere implementation from http://stackoverflow.com/a/25674762
    self.cameraSphere = [[SCNNode alloc] init];
    [self.cameraSphere addChildNode:self.camera];
    [self.scene.rootNode addChildNode:self.cameraSphere];
    
    [self.cameraSphere setEulerAngles:SCNVector3Make(self.cameraSphere.eulerAngles.x - M_PI_2, self.cameraSphere.eulerAngles.y - 0, self.cameraSphere.eulerAngles.z)];
    
//
//    
//    [self.camera setPosition:SCNVector3Make(0.0, distance, -20.0)];
//    [self.camera setRotation:SCNVector4Make(1.0, 0.0, 0.0, -(M_PI / 2))];
    //[self.scene.rootNode addChildNode:self.camera];
    
    // add lighting
    SCNNode *ambientNode = [[SCNNode alloc] init];
    ambientNode.light = [[SCNLight alloc] init];
    ambientNode.light.type = SCNLightTypeAmbient;
    ambientNode.light.color = [UIColor colorWithWhite:0.67 alpha:1.0];
    [self.scene.rootNode addChildNode:ambientNode];
    
    // TODO: improve the lighting so it's more even
    SCNNode *omniNode = [[SCNNode alloc] init];
    omniNode.light = [[SCNLight alloc] init];
    omniNode.light.type = SCNLightTypeOmni;
    omniNode.light.color = [UIColor colorWithWhite:0.75 alpha:1.0];
    omniNode.position = SCNVector3Make(100.0, 400.0, 100.0);
    [self.scene.rootNode addChildNode:omniNode];

}

- (void)drawFlatShapes {
    NSArray *shapes = [(Data *)[Data sharedData] fetchShapes];
    
    // draw a Plane that will represent the floor
    SCNGeometry *floorGeom = [SCNPlane planeWithWidth:[(Data *)[Data sharedData] screenWidth] height:[(Data *)[Data sharedData] screenHeight]];
    [floorGeom.firstMaterial.diffuse setContents:[UIColor whiteColor]];
    self.floor = [SCNNode nodeWithGeometry:floorGeom];
    
    for (Shape *shape in shapes) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        
        NSValue *firstValue = [shape.sketchyRepresentation firstObject];
        CGPoint firstPoint = [firstValue CGPointValue];
        
        CGPoint flippedStart = CGPointMake(firstPoint.x, [(Data *)[Data sharedData] screenHeight] - firstPoint.y);
        [path moveToPoint:flippedStart];
        
        for (int i = 1; i < shape.sketchyRepresentation.count; i++) {
            NSValue *val = [shape.sketchyRepresentation objectAtIndex:i];
            CGPoint point = [val CGPointValue];
            
            // translate the coordinate system
            CGPoint newPoint = CGPointMake(point.x, [(Data *)[Data sharedData] screenHeight] - point.y);
            
            [path addLineToPoint:newPoint];
        }
        
        // naïvely close the shape
        [path closePath];
        
        [path setLineWidth:1.0];
        
        
        // Commented out if we deicde to use more complex geometry
        //NSData *data = [NSData dataWithBytes:vertices length:sizeof(vertices)];
        //SCNGeometrySource *geomSource = [SCNGeometrySource geometrySourceWithData:data semantic:SCNGeometrySourceSemanticVertex vectorCount:c floatComponents:YES componentsPerVector:3 bytesPerComponent:sizeof(float) dataOffset:offsetof(SCNVector3, x) dataStride:sizeof(SCNVector3)];
        //SCNGeometrySource *geomSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:c];
        //SCNGeometry *geom = [SCNGeometry geometryWithSources:@[geomSource] elements:<#(NSArray *)#>]
        
        
        SCNGeometry *geom = [SCNShape shapeWithPath:path extrusionDepth:1.0];
        
        // color the shape
        [geom.firstMaterial.diffuse setContents:shape.color];
        
        SCNNode *shapeToAdd = [SCNNode nodeWithGeometry:geom];
        
        // offset the node so the coordinates start in the bottom right of the "floor"
        shapeToAdd.position = SCNVector3Make(-([(Data *)[Data sharedData] screenWidth] / 2), -([(Data *)[Data sharedData] screenHeight] / 2), 1.0);
        
        // add the shape to the floor
        [self.floor addChildNode:shapeToAdd];
        
    }
    
    // add the entire floor to the scene
    [self.scene.rootNode addChildNode:self.floor];
    
    // rotate the floor node so it's a floor and not a wall
    self.floor.rotation = SCNVector4Make(1.0, 0.0, 0.0, -(M_PI / 2));
}

// MARK: Camera Control (and temporary extrusion)
- (IBAction)did1FingerPan:(UIPanGestureRecognizer *)sender {
    
    if (self.tempExtrudeButton.selected) {  // handle extrusion temporarily
        // TODO: Remove this once we get multitouch working
        if (sender.state == UIGestureRecognizerStateBegan) {
            self.prevPosition = [sender translationInView:self.sceneView];
            NSArray *hits = [self.sceneView hitTest:[sender locationInView:self.sceneView] options:nil];
            if ([hits count] > 0) {
                for (SCNHitTestResult *hit in hits) {
                    if ([hit node] != self.floor && [hit node] != self.camera && [hit node] != self.cameraSphere) {
                        self.extrudingNode = [hit node];
                        break;
                    }
                }
            }
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            CGPoint newPosition = [sender translationInView:self.sceneView];
            float delY = newPosition.y - self.prevPosition.y;
            
            
            if (((SCNShape *)self.extrudingNode.geometry).extrusionDepth > 0.0 || delY < 0) {
                ((SCNShape *)self.extrudingNode.geometry).extrusionDepth -= delY;
                NSLog(@"%f", ((SCNShape *)self.extrudingNode.geometry).extrusionDepth);
                [self.extrudingNode setPosition:SCNVector3Make(self.extrudingNode.position.x, self.extrudingNode.position.y, self.extrudingNode.position.z - (delY * 0.5))];
            }
            
            
            self.prevPosition = newPosition;
        }
    } else {
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
    
    // FIXME: This isn't working yet. translationInView is returning nil
    // for some reason
    
//    if (sender.state == UIGestureRecognizerStateBegan) {
//        self.prevPosition = [sender translationInView:self.sceneView];
//        NSArray *hits = [self.sceneView hitTest:[sender locationInView:self.sceneView] options:nil];
//        if ([hits count] > 0) {
//            self.extrudingNode = [((SCNHitTestResult *)hits.firstObject) node];
//        }
//    } else if (sender.state == UIGestureRecognizerStateChanged) {
//        CGPoint newPosition = [sender translationInView:self.sceneView];
//        float delY = newPosition.y - self.prevPosition.y;
//        
//        if ([self.extrudingNode isKindOfClass:[SCNShape class]]) {
//            ((SCNShape *)self.extrudingNode).extrusionDepth += delY;
//            [self.extrudingNode setPosition:SCNVector3Make(self.extrudingNode.position.x, self.extrudingNode.position.y, self.extrudingNode.position.z + (delY / 2))];
//        }
//        
//        self.prevPosition = newPosition;
//    }
}


- (IBAction)extrudePressed:(UIButton *)sender {
    sender.selected = !sender.selected;
}


@end
