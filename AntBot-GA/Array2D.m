//
//  Array2D.m
//  AntBot-GA
//
//  Created by Joshua Hecker on 4/22/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

#import "Array2D.h"

@implementation Array2D

-(id)initWithRows:(size_t)rows cols:(size_t)cols {
    self = [super init];
    if (self != nil)
    {
        numberOfRows = rows;
        numberOfColumns = cols;
        backingStore = [NSMutableArray arrayWithCapacity:numberOfRows * numberOfColumns];
    }
    return self;
}

-(id)objectAtRow:(size_t)row col:(size_t)col {
    if (col >= numberOfColumns) {
        [NSException raise:@"Invalid column value" format:@"column of %zd is invalid",col];
    }
    size_t index = row * (numberOfColumns + col);
    return [backingStore objectAtIndex:index];
}

-(void)setObjectAt:(size_t)row :(size_t)col to:(id)value {
    if (col >= numberOfColumns) {
        [NSException raise:@"Invalid column value" format:@"column of %zd is invalid",col];
    }
    size_t index = row * (numberOfColumns + col);
    [backingStore replaceObjectAtIndex:index withObject:value];
}

@end
