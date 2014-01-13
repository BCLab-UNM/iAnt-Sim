#import <Foundation/Foundation.h>

@interface Cluster : NSObject

-(id) initWithCenter:(NSPoint)_center width:(int)_width andHeight:(int)_height;

@property (nonatomic) NSPoint center;
@property (nonatomic) int width;
@property (nonatomic) int height;

@end
