//
//  SketchViewController.h
//  Square3
//
//  Created by Harry Shamansky on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shape.h"
#import "Data.h"
@import Foundation;

@interface SketchViewController : UIViewController

@property UIColor *drawingColor;
@property Shape *shapeInProgress;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *tempImageView;
@property (weak, nonatomic) IBOutlet UIView *colorSwatch;
@property (weak, nonatomic) IBOutlet UISlider *colorSlider;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

