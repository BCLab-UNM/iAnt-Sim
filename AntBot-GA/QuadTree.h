#import <Foundation/Foundation.h>

@interface QuadTree : NSObject {}

-(id) initWithRect:(NSRect)rect;

@property (nonatomic) NSRect shape;
@property (nonatomic) int area;
@property (nonatomic) double percentExplored;
@property (nonatomic) BOOL dirty;

@end
