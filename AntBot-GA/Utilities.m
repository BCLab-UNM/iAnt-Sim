#import "Utilities.h"

@implementation Utilities

+ (void)appendText:(NSString *)text toFile:(NSString *)filePath {
    
    // NSFileHandle won't create the file for us, so we need to check to make sure it exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        
        // the file doesn't exist yet, so we can just write out the text using the
        // NSString convenience method
        
        NSError *error;
        BOOL success = [text writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!success) {
            // handle the error
            NSLog(@"%@", error);
        }
        
    }
    else {
                      
        // the file already exists, so we should append the text to the end

        // get a handle to the file
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];

        // move to the end of the file
        [fileHandle seekToEndOfFile];

        // convert the string to an NSData object
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];

        // write the data to the end of the file
        [fileHandle writeData:textData];

        // clean up
        [fileHandle closeFile];
    }
}



//*NOTE* These functions moved from Util.h -- may be converted to Obj-C in the future

/*
 * Returns a random float in the range [0,x].
 */
static inline float randomFloat(float x) {
    return ((float)random() / ((long)RAND_MAX + 1)) * x;
}

/*
 * Returns a random float in the range [x,y].
 */
static inline float randomFloatRange(float x, float y) {
    return randomFloat(y - x) + x;
}

/*
 * Returns a random integer in the range [0,x).
 */
static inline int randomInt(int x) {
    return random() % x; //Note that modulo bias does exist here.
}

/*
 * Returns a random integer in the range [x,y).
 */
static inline int randomIntRange(int x, int y) {
    return randomInt(y - x) + x;
}

/*
 * Returns the distance between x and y.
 */
static inline float pointDistance(float x1, float y1, float x2, float y2) {
    float dx = (x1 - x2);
    float dy = (y1 - y2);
    return sqrtf((dx * dx) + (dy * dy));
}

/*
 * Returns (in radians) the angle between x and y.
 */
static inline float pointDirection(float x1, float y1, float x2, float y2) {
    return atan2f(y2 - y1, x2 - x1);
}

/*
 * Returns a sample from a normal distribution with mean m and standard deviation s.
 */
static inline float randomNormal(float m, float s) {
    float u = randomFloat(1.);
    float v = randomFloat(1.);
    float x = sqrtf(-2 * logf(1.0 - u));
    
    if(roundf(randomFloat(1.)) == 0){
        return x * cos(2 * M_PI * v) * s + m;
    }
    
    return x * sin(2 * M_PI * v) * s + m;
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
    return -logf(randomFloat(1.)) / lambda;
}

/*
 * Returns proper modulus of dividend and divisor
 */
static inline float pmod(float dividend, float divisor)
{
    float temp = fmod(dividend, divisor);
    while(temp < 0) {
        temp += divisor;
    }
    return temp;
}

/*
 * Returns passed value clipped between min and max.
 */
static inline float clip(float x, float min, float max) {
    return (x < min) ? min : ((x > max) ? max : x);
}

/*
 * Given dimensions of a grid/world, returns an NSPoint corresponding
 * to a random point located on the edge of the world.
 */
static inline NSPoint edge(NSSize size) {
    int rw = randomInt(size.width);
    int rh = randomInt(size.height);
    switch(randomInt(4)) {
        case 0: return NSMakePoint(rw, 0); break;
        case 1: return NSMakePoint(0, rh); break;
        case 2: return NSMakePoint(rw, size.height - 1); break;
        case 3: return NSMakePoint(size.width - 1, rh); break;
    }
    return NSMakePoint(-1, -1); //Should never happen.
}

/*
 * Returns Poisson cumulative probability at a given k and lambda
 */
static inline float poissonCDF(float k, float lambda) {
    float sumAccumulator = 1;
    float factorialAccumulator = 1;
    
    for (int i = 1; i <= floor(k); i++) {
        factorialAccumulator *= i;
        sumAccumulator += pow(lambda, i) / factorialAccumulator;
    }
    
    return (exp(-lambda) * sumAccumulator);
}

/*
 * Returns exponential cumulative probability at a given x and lambda
 */
static inline float exponentialCDF(float x, float lambda) {
    return (1 - exp(-lambda * x));
}

/*
 * Returns decay of quantity at time given rate of change lambda
 */
static inline float exponentialDecay(float quantity, float time, float lambda) {
    return (quantity * exp(-lambda * time));
}

@end