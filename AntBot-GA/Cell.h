#import <Foundation/Foundation.h>
#import "QuadTree.h"
#import "Tag.h"

@class Tag;

@interface Cell : NSObject {}

@property (nonatomic) Tag* tag;
@property (nonatomic) QuadTree* region;
@property (nonatomic) BOOL isClustered;
@property (nonatomic) BOOL isExplored;

@end