<<<<<<< HEAD
//
//  Cluster.m
//  AntBot-GA
//
//  Created by Justin on 10/31/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

=======
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
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
