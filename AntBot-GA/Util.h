#ifndef __SIMSANDBOX_UTIL_H
#define __SIMSANDBOX_UTIL_H

/*
 * Returns a random float in the range [0,x].
 */
static inline float randomFloat(float x) {
    //return (((float)arc4random())/0x100000000)*x;
    return ((float)random()/((long)RAND_MAX+1))*x;
}

/*
 * Returns a random float in the range [x,y].
 */
static inline float randomFloatRange(float x, float y) {
    return randomFloat(y-x)+x;
}

/*
 * Returns a random integer in the range [0,x).
 */
static inline int randomInt(int x) {
    return random() % x; //hurr
}

/*
 * Returns a random integer in the range [x,y).
 */
static inline int randomIntRange(int x, int y) {
    return randomInt(y-x)+x;
}

/*
 * Returns the distance between x and y.
 */
static inline float pointDistance(float x1, float y1, float x2, float y2) {
    float dx = (x1-x2);
    float dy = (y1-y2);
    return sqrtf((dx*dx)+(dy*dy));
}

/*
 * Returns (in radians) the angle between x and y.
 */
static inline float pointDirection(float x1, float y1, float x2, float y2) {
    return atan2f(y2-y1,x2-x1);
}

/*
 * Returns a sample from a normal distribution with mean m and standard deviation s.
 */
static inline float randomNormal(float m, float s) {
    float u = randomFloat(1.);
    float v = randomFloat(1.);
    float x = sqrtf(-2 * logf(1.0-u));
    
    if(roundf(randomFloat(1.))==0){
        return x*cos(2*M_PI*v)*s+m;
    }
    
    return x*sin(2*M_PI*v)*s+m;
}

/*
 * Returns sample from a log-normal distribution with location parameter mu and scale parameter sigma
 */
static inline float randomLogNormal(float mu, float sigma) {
    return expf(randomNormal(mu, sigma));
}

/*
 * Returns a sample from an exponential distribution with rate parameter lambda
 */
static inline float randomExponential(float lambda) {
    return -logf(randomFloat(1.))/lambda;
}

/*
 * Returns proper modulus of dividend and divisor
 */
static inline float pmod(float dividend, float divisor)
{
    float temp = fmod(dividend,divisor);
    while(temp < 0){temp += divisor;}
    return temp;
}

/*
 * Returns passed value clipped between min and max.
 */
static inline float clip(float x, float min, float max) {
    return (x<min) ? min : ((x>max) ? max : x);
}

/*
 * Given dimensions of a grid/world, returns an NSPoint corresponding
 * to a random point located on the edge of the world.
 */
static inline NSPoint edge(int w, int h) {
    int rw = randomInt(w);
    int rh = randomInt(h);
    switch(randomInt(4)) {
        case 0: return NSMakePoint(rw,0); break;
        case 1: return NSMakePoint(0,rh); break;
        case 2: return NSMakePoint(rw,h-1); break;
        case 3: return NSMakePoint(w-1,rh); break;
    }
    return NSMakePoint(-1,-1); //Should never happen.
}

/*
 * Returns exponential cumulative probability at a given x and lambda
 */
static inline float exponentialCDF(float x, float lambda) {
    return (1 - exp(-lambda*x));
}

/*
 * Returns decay of quantity at time given rate of change lambda
 */
static inline float exponentialDecay(float quantity, float time, float lambda) {
    return (quantity * exp(-lambda*time));
}

static inline CGFloat NSDistance(NSPoint point1,NSPoint point2)
{
    float dx = point2.x - point1.x;
    float dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy);
};

/*
 * Introduces error into recorded tag position - Simulates localization error in real robot
 */
static inline NSPoint perturbTagPosition(bool realWorldError,NSPoint position) {
    if (realWorldError) {
        position.x = roundf(clip(randomNormal(position.x - 17.6, 78.9),0,gridWidth-1));
        position.y = roundf(clip(randomNormal(position.y - 14.6, 46.7),0,gridHeight-1));
    }
    return position;
}

/*
 * Introduces error into target position - Simulates traveling error in real robot
 */
static inline NSPoint perturbTargetPosition(bool realWorldError, NSPoint position) {
    if (realWorldError) {
        position.x = roundf(clip(randomNormal(position.x + 6.63, 43.5),0,gridWidth-1));
        position.y = roundf(clip(randomNormal(position.y + 10.6, 58.4),0,gridHeight-1));
    }
    return position;
}

/*
 * Introduces error into tag reading - Simulates probability of missing tag
 */
static inline bool detectTag(bool realWorldError) {
    return (realWorldError ? (randomFloat(1.) <= 0.55) : TRUE);
}

/*
 * Introduces error into neighbor reading = Simulates probability of missing neighboring tags
 */
static inline bool detectNeighbor(bool realWorldError) {
    return (realWorldError ? randomFloat(1.) <= 0.43 : TRUE);
}


#endif
