#import "Cluster.h"

@implementation Cluster

@synthesize center;
@synthesize width, height;


-(id) initWithCenter:(NSPoint)_center width:(int)_width andHeight:(int)_height {
    if(self = [super init]) {
        center = _center;
        width = _width;
        height = _height;
    }
    return self;
}

/*
 * Executes unsupervised clustering algorithm Expectation-Maximization (EM) on input
 * Returns trained instantiation of EM if all robots home, untrained otherwise
 */
+(cv::EM) trainOptimalEMWith:(NSMutableArray*)foundTags {
    int k = 0; //number of clusters
    
    cv::EM emModel;
    float emBIC = std::numeric_limits<float>::infinity();
    
    //Run EM on aggregate tag array
    if ([foundTags count]) {
        //Create [totalFoundTags count] x 2 matrix
        cv::Mat aggregate((int)[foundTags count], 2, CV_64F);
        int counter = 0;
        //Iterate over all tags
        for (Tag* tag in foundTags) {
            //Copy x and y location of tag into matrix
            aggregate.at<double>(counter, 0) = [tag position].x;
            aggregate.at<double>(counter, 1) = [tag position].y;
            counter++;
        }

        //Train EM and calculate BIC for k = 1, 2, ...
        //Terminate loop when BIC stops decreasing
        cv::EM oldModel;
        float oldBIC;
        do {
            //Update
            oldModel = emModel;
            oldBIC = emBIC;
            k++;
            //Create output array for log likelihood values
            cv::Mat ll((int)[foundTags count], 1, CV_64F);
            
            //Train and store model
            emModel = cv::EM(k);
            emModel.train(aggregate, ll);
            
            //Calculate and store BIC
            float llSum = cv::sum(ll)[0];
            emBIC = bic(llSum, componentsEM(k, 2), (int)[foundTags count]);

        } while (emBIC - oldBIC < 0);
        emModel = oldModel;
    }

    return emModel;
}
                      
@end