#import "Globals.h"

@implementation Globals

int pileRadius;
int searchDelay;
int crossoverRate;
int stepCount;
int gridWidth;
int gridHeight;
int nestX;
int nestY;
int M_2PI;
int wirelessRange;

+(void) initialize {
    pileRadius = 2;
    searchDelay = 4;
    crossoverRate = 10;
    stepCount = 3600;
    gridWidth = 125;
    gridHeight = 125;
    nestX = gridWidth / 2;
    nestY = gridHeight / 2;
    M_2PI = 2 * M_PI;
    wirelessRange = 10;
}

@end
