#import <Foundation/Foundation.h>
#import "Tag.h"

@interface Cell : NSObject {}

@property (nonatomic) Tag* tag;
@property (nonatomic) BOOL isClustered;
@property (nonatomic) BOOL isExplored;

@end