//
//  ExtrudeViewController.h
//  Square3
//
//  Created on 4/27/15.
//

#import <UIKit/UIKit.h>
#import "Data.h"
@import SceneKit;

@interface ExtrudeViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet SCNView *sceneView;
@property SCNScene *scene;
@property SCNNode *camera;
@property SCNNode *cameraSphere;
@property SCNNode *floor;

// properties to keep track of panning and pinching
@property CGPoint prevPosition;
@property CGFloat prevScale;

// node currently being extruded
@property SCNNode *extrudingNode;

// temporary button to allow extrusion
@property (weak, nonatomic) IBOutlet UIButton *tempExtrudeButton;

@end

