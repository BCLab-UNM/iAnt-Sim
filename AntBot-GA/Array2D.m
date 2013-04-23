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
        for (int i = 0; i < numberOfRows * numberOfColumns; i++) {
            [backingStore addObject:[NSNull null]];
        }
    }
    return self;
}

-(id)objectAtRow:(size_t)x col:(size_t)y {
    if (y >= numberOfColumns) {
        [NSException raise:@"Invalid column value" format:@"column of %zd is invalid",y];
    }
    size_t index = x * numberOfColumns + y;
    return [backingStore objectAtIndex:index];
}

-(void)setObjectAtRow:(size_t)x col:(size_t)y to:(id)value {
    if (y >= numberOfColumns) {
        [NSException raise:@"Invalid column value" format:@"column of %zd is invalid",y];
    }
    size_t index = x * numberOfColumns + y;
    [backingStore replaceObjectAtIndex:index withObject:value];
}


#pragma NSFastEnumeration methods

/*
 * We simply forward the fast enumeration call directly to backingStore
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [backingStore countByEnumeratingWithState:state objects:buffer count:len];
}


#pragma NSCopying methods

-(id)copyWithZone:(NSZone *)zone {
    Array2D *arrayCopy = [[[self class] allocWithZone:zone] init];
    if (arrayCopy) {
        arrayCopy = self;
    }
    return arrayCopy;
}

@end
