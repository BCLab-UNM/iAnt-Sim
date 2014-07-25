#import <Foundation/Foundation.h>
#import "Array2D.h"
#import "Cell.h"
#import "QuadTree.h"

@interface Decomposition : NSObject

<<<<<<< HEAD
+(NSMutableArray*) runDecomposition:(NSMutableArray*)regions;
=======
@property (nonatomic) NSMutableArray* baseRegions;

-(id) initWithRegions:(NSMutableArray*)_baseRegions;
-(NSMutableArray*) runDecomposition:(NSMutableArray*)regions;
>>>>>>> faf9618

@end
