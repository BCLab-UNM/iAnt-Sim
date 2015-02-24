//
//  Pile.h
//  AntBot-GA
//
//  Created by Drew Levin on 2/21/15.
//  Copyright (c) 2015 AntBot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tag.h"
#import "Cell.h"
#import "Utilities.h"

@class Tag;
@class Cell;

@interface Pile : NSObject {}

@property (nonatomic) int capacity;
@property (nonatomic) int radius;
@property (nonatomic) NSPoint position;
@property (nonatomic) NSMutableArray* tagArray;

-(Pile*) initAtX:(int)_x andY:(int)_y withCapacity:(int)_capacity andRadius:(int)_radius;

-(UInt8) numTags;

#ifdef __cplusplus
-(void) addTagtoGrid:(std::vector<std::vector<Cell*>>&)grid ofSize:(NSSize)gridSize;
-(void) removeTagFromGrid:(std::vector<std::vector<Cell*>>&)grid;
#endif
-(void) addTag:(Tag*)_tag;
-(void) removeSpecificTag:(Tag*)_tag;

-(BOOL) containsPointX:(float)_x andY:(float)y;

-(void) shuffle;

@end
