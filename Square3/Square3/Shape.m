//
//  Shape.m
//  Square3
//
//  Created by Harry Shamansky on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import "Shape.h"

@implementation Shape

- (NSArray *)preferredRepresentation {
    return self.showExactRepresentation ? self.exactRepresentation : self.sketchyRepresentation;
}

@end
