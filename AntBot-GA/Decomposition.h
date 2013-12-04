#import <Foundation/Foundation.h>
#import "Array2D.h"
#import "Cell.h"
#import "QuadTree.h"

@interface Decomposition : NSObject

+(NSMutableArray*) runDecomposition:(NSMutableArray*)regions;

@end
