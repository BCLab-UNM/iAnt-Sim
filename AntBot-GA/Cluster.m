//
//  Cluster.m
//  AntBot-GA
//
//  Created by Justin on 10/31/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

#import "Cluster.h"

@implementation Cluster

@synthesize center;
@synthesize width, height;

-(id) initWithCenter:(NSPoint)_center width:(int)_width andHeight:(int)_height {
    if(self = [super init]) {
        center = _center;
        width = _width;
        height = _height;
    }
    return self;
}

@end
