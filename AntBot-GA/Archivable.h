#import <Foundation/Foundation.h>

@protocol Archivable <NSObject>

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;
-(void) writeParametersToFile:(NSString*)file;
+(void) writeParameterNamesToFile:(NSString*)file;

@end