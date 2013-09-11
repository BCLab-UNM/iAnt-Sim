#import <Foundation/Foundation.h>

@interface Tag : NSObject <NSCopying> {}

-(id) initWithX:(int)_x andY:(int)_y;

@property (nonatomic) NSPoint position;
@property (nonatomic) BOOL pickedUp;
@property (nonatomic) BOOL discovered;

@end