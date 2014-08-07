#import <Foundation/Foundation.h>
#import "Array2D.h"
#import "Cell.h"
#import "QuadTree.h"

@interface Decomposition : NSObject

@property (nonatomic) NSMutableArray* baseRegions;

-(id) initWithRegions:(NSMutableArray*)_baseRegions;
-(NSMutableArray*) runDecomposition:(NSMutableArray*)regions;
-(double) checkExploredness:(QuadTree*)region;

@end
