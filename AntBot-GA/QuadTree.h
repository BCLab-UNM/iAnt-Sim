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
