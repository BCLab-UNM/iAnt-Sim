#ifndef __IANT_GA_CONSTANTS_H
#define __IANT_GA_CONSTANTS_H

static const float M_2PI = 2 * M_PI;
static const NSPoint NSNullPoint = {-1, -1};

static const int TournamentSelectionId = 0;
static const int RankBasedElitistSelectionId = 1;

static const int IndependentAssortmentCrossId = 0;
static const int UniformPointCrossId = 1;
static const int OnePointCrossId = 2;
static const int TwoPointCross = 3;

static const int ValueDependentVarMutId = 0;
static const int DecreasingVarMutId = 1;
static const int FixedVarMutId = 2;

#endif