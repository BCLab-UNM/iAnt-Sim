//
//  Globals.m
//  AntBot-GA
//
//  Created by Joshua Hecker on 4/21/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

#import "Globals.h"

@implementation Globals

int pileRadius;
int searchDelay;
int crossoverRate;
int stepCount;
int gridWidth;
int gridHeight;
int gridSize;
int nestX;
int nestY;
int M_2PI;

+(void) initialize {
    pileRadius = 2;
    searchDelay = 4;
    crossoverRate = 10;
    stepCount = 6750;
    gridWidth = 90;
    gridHeight = 90;
    gridSize = gridWidth * gridHeight;
    nestX = gridWidth / 2;
    nestY = gridHeight / 2;
    M_2PI = 2 * M_PI;
}

@end
