<<<<<<< HEAD
<<<<<<< HEAD
//
//  QuadTree.h
//  AntBot-GA
//
//  Created by Justin on 8/7/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

=======
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
=======
>>>>>>> faf9618
#import <Foundation/Foundation.h>
#import "Array2D.h"

#define CELL_NOT_IN_CLUSTER 0
#define CELL_IN_CLUSTER 1

@interface QuadTree : NSObject {}

-(id) initWithHeight:(int)_height width:(int)_width origin:(NSPoint)_origin cells:(Array2D*)_cells andParent:(QuadTree*)_parent;
-(void) bubbleUpPercentage;

@property (nonatomic) NSPoint origin;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) double percentExplored;
@property (nonatomic) BOOL dirty;
@property (nonatomic) Array2D* cells;
@property (nonatomic) QuadTree* parent;
@property (nonatomic) NSMutableArray* children;

@end
