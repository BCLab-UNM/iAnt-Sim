#import <Foundation/Foundation.h>

@protocol Archivable <NSObject>

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;
-(void) writeParameters:(NSMutableDictionary*)parameters toFile:(NSString*)file;
+(void) writeParameterNamesToFile:(NSString*)file;

@end