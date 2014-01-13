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
