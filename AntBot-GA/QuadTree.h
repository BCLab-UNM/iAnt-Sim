#import <Foundation/Foundation.h>

#define CELL_NOT_IN_CLUSTER 0
#define CELL_IN_CLUSTER 1

@interface QuadTree : NSObject {}

-(id) initWithRect:(NSRect)rect;

@property (nonatomic) NSRect shape;
@property (nonatomic) int area;
@property (nonatomic) double percentExplored;
@property (nonatomic) BOOL needsDecomposition;

@end
