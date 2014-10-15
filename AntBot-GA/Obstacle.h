#import <Foundation/Foundation.h>

@interface Obstacle : NSObject <NSCopying> {}

-(id) initWithX:(int)_x andY:(int)_y;

@property (nonatomic) NSPoint position;

@end
