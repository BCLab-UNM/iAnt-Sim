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
#import <Foundation/Foundation.h>
#import "Array2D.h"

#define CELL_NOT_IN_CLUSTER 0
#define CELL_IN_CLUSTER 1

@interface QuadTree : NSObject {}

-(id) initWithHeight:(int)_height width:(int)_width origin:(NSPoint)_origin andCells:(Array2D*)_cells;

@property (nonatomic) NSPoint origin;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) Array2D* cells;

@end
