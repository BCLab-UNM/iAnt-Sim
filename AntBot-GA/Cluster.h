//
//  Cluster.h
//  AntBot-GA
//
//  Created by Justin on 10/31/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cluster : NSObject

-(id) initWithCenter:(NSPoint)_center width:(int)_width andHeight:(int)_height;

@property (nonatomic) NSPoint center;
@property (nonatomic) int width;
@property (nonatomic) int height;

@end
