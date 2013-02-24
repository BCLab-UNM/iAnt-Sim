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

#endif
