#import <Foundation/Foundation.h>
#import "Cell.h"
#import "QuadTree.h"

@interface Decomposition : NSObject

@property (nonatomic) float exploredCutoff;

#ifdef __cplusplus

@property (nonatomic) std::vector<std::vector<Cell*>> grid;

-(id) initWithGrid:(std::vector<std::vector<Cell*>>)_grid andExploredCutoff:(float)_exploredCutoff;

-(NSMutableArray*) runDecomposition:(NSMutableArray*)regions;
-(double) checkExploredness:(QuadTree*)region;

#endif

@end
