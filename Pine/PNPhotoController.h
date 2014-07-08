//
//  PNPhotoController.h
//  Pine
//
//  Created by soojin on 6/29/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMPThread.h"

@interface PNPhotoController : NSObject

+ (void)imageForThread:(TMPThread *)thread completion:(void(^)(UIImage *image))completion;

@end
