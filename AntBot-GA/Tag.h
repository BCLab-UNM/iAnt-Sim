#import <Foundation/Foundation.h>
#import "Pile.h"

@class Pile;
@class Tag;

@interface Tag : NSObject <NSCopying> {}

@property (nonatomic) NSPoint position;
@property (nonatomic) BOOL pickedUp;
@property (nonatomic) BOOL discovered;
@property (nonatomic) int cluster;
@property (nonatomic) Pile* pile;

-(id) initWithX:(int)_x Y:(int)_y andCluster:(int)_cluster;
-(id) initWithX:(int)_x Y:(int)_y andPile:(Pile*)_pile;
-(void) removeFromPile;

@end