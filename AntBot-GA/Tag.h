#import <Foundation/Foundation.h>

@interface Tag : NSObject {}

-(id) initWithX:(int)_x andY:(int)_y;

@property (nonatomic) int x;
@property (nonatomic) int y;
@property (nonatomic) BOOL pickedUp;
@property (nonatomic) BOOL discovered;

@end