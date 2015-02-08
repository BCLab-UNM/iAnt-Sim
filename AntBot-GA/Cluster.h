#import <Foundation/Foundation.h>
#import "Tag.h"
#import "Utilities.h"

@interface Cluster : NSObject

-(id) initWithCenter:(NSPoint)_center width:(int)_width andHeight:(int)_height;

#ifdef __cplusplus
+(cv::EM) trainOptimalEMWith:(NSMutableArray*)foundTags;
#endif

@property (nonatomic) NSPoint center;
@property (nonatomic) int width;
@property (nonatomic) int height;

@end
