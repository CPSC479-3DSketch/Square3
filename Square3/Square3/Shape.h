//
//  Shape.h
//  Square3
//
//  Created by Harry Shamansky on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum { Triangle = 3, Rectangle = 4, Pentagon = 5, Hexagon = 6, Heptagon = 7, Octagon = 8, Nonagon = 9, Decagon = 10, Elvagon = 11, Dodecagon = 12, Circle = 365 } ShapeType;

@interface Shape : NSObject

// Two representations of the 2D shape. Both are arrays of cartesian points.
// if exactRepresentation is nil, the exact shape has not yet been determined, or
// cannot be determined.
@property NSMutableArray *sketchyRepresentation;
@property NSMutableArray *exactRepresentation;
@property (readonly) NSArray *preferredRepresentation;
@property ShapeType shapeName;

// A boolean to determine whether the user wants to view her original sketch
// or an exact representation of it
@property bool showExactRepresentation;

// the shape's color, since this is super easy to add.
@property UIColor *color;

// Property to capture the depth of the extrusion
@property CGFloat extrusionDepth;

@end