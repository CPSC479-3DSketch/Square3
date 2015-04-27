//
//  Data.h
//  Square3
//
//  Created by Hunter Ford on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Shape.h"

@interface Data : NSObject

@property NSMutableArray *shapes;

+ (id)sharedData;
- (NSMutableArray *) fetchShapes;
- (void) addShape: (Shape *)shape;
- (void) loadDataFromDisk;
- (void) saveDataToDisk;

@end
