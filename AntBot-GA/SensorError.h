#import <Foundation/Foundation.h>
#import "Archivable.h"
#import "Utilities.h"

@interface SensorError : NSObject <Archivable>

-(id)initRandom;
<<<<<<< HEAD
-(id)initObserved;
=======
>>>>>>> faf9618

-(NSPoint) perturbTagPosition:(NSPoint)position withGridSize:(NSSize)size andGridCenter:(NSPoint)center;
-(NSPoint) perturbTargetPosition:(NSPoint)position withGridSize:(NSSize)size andGridCenter:(NSPoint)center;
-(BOOL)detectTag;
-(BOOL)detectNeighbor;

@property (nonatomic) NSPoint localizationSlope;
@property (nonatomic) NSPoint localizationIntercept;

@property (nonatomic) NSPoint travelingSlope;
@property (nonatomic) NSPoint travelingIntercept;

@property (nonatomic) float tagDetectionProbability;
@property (nonatomic) float neighborDetectionProbability;

@property (nonatomic) float fitness;

@end
