//
//  Data.m
//  Square3
//
//  Created by Hunter Ford on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import "Data.h"

@implementation Data

+ (id)sharedData {
    static Data *sharedData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedData = [[self alloc] init];
    });
    return sharedData;
}

-(id)init{
    if (self = [super init])
        self.shapes = [[NSMutableArray alloc] init];
    
    return self;
}

- (NSMutableArray *)fetchShapes {
    return self.shapes;
}

- (void) clearShapes {
    [self.shapes removeAllObjects];
}

- (void) addShape:(Shape *)shape {
    [self.shapes addObject:shape];
}

- (void) loadDataFromDisk{
    
}

- (void) saveDataToDisk{
    
}

@end
