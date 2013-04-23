//
//  Array2D.h
//  AntBot-GA
//
//  Created by Joshua Hecker on 4/22/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Array2D : NSObject <NSFastEnumeration, NSCopying> {
    NSMutableArray* backingStore;
    size_t numberOfRows;
    size_t numberOfColumns;
}

-(id)initWithRows:(size_t) rows cols:(size_t) cols;
-(id)objectAtRow:(size_t)x col:(size_t)y;
-(void)setObjectAtRow:(size_t)x col:(size_t)y to:(id)value;

@end