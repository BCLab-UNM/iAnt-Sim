#import <Foundation/Foundation.h>

@interface Tag : NSObject <NSCopying> {}

-(id) initWithX:(int)_x Y:(int)_y andCluster:(int)_cluster;

@property (nonatomic) NSPoint position;
@property (nonatomic) BOOL pickedUp;
@property (nonatomic) BOOL discovered;
@property (nonatomic) int cluster;

@end