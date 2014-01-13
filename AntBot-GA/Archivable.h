#import <Foundation/Foundation.h>

@protocol Archivable <NSObject>

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;

@end