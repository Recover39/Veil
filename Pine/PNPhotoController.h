//
//  PNPhotoController.h
//  Pine
//
//  Created by soojin on 6/29/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PNPhotoController : NSObject

+ (void)imageForPost:(NSDictionary *)post completion:(void(^)(UIImage *image))completion;

@end