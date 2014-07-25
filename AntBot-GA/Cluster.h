<<<<<<< HEAD
<<<<<<< HEAD
//
//  Cluster.h
//  AntBot-GA
//
//  Created by Justin on 10/31/13.
//  Copyright (c) 2013 AntBot. All rights reserved.
//

=======
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
=======
>>>>>>> faf9618
#import <Foundation/Foundation.h>

@interface Cluster : NSObject

-(id) initWithCenter:(NSPoint)_center width:(int)_width andHeight:(int)_height;

@property (nonatomic) NSPoint center;
@property (nonatomic) int width;
@property (nonatomic) int height;

@end
