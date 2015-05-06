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
  
    SCNCamera *cam = [[SCNCamera alloc] init];
    cam.automaticallyAdjustsZRange = YES;
    cam.usesOrthographicProjection = NO;
    float distance = 530.0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      distance = 800.0;
    }
    [self setCamera:[[SCNNode alloc] init]];
    [self.camera setCamera: cam];
    [self.camera setPosition:SCNVector3Make(0.0, 0.0, distance)];
  
    self.firstLoad = YES;
    return self;
}

- (BOOL) isFirstLoad{
  
  BOOL flag = self.firstLoad;
  
  if (self.firstLoad)
    self.firstLoad = NO;
  
  return flag;
}

- (NSMutableArray *)fetchShapes {
    return self.shapes;
}

- (SCNNode *) fetchCamera{
  return self.camera;
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
