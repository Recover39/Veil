//
//  PNPhotoController.m
//  Pine
//
//  Created by soojin on 6/29/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNPhotoController.h"
#import "SAMCache.h"

@implementation PNPhotoController

+ (void)imageForURLString:(NSString *)imageURLString completion:(void (^)(UIImage *))completion
{
    UIImage *imageFromCache = [[SAMCache sharedCache] imageForKey:imageURLString];
    if (imageFromCache) {
        completion(imageFromCache);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/%@", kImageServerURL, imageURLString];
    NSURL *imageURL = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:imageURL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:urlRequest completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([httpResponse statusCode] == 200) {
            //SUCCESS
            @autoreleasepool {
            NSData *data = [NSData dataWithContentsOfURL:location];
            UIImage *image = [UIImage imageWithData:data];
            [[SAMCache sharedCache] setImage:image forKey:imageURLString];
            
            //Return image to completion block
            completion(image);
            }
        } else {
            //FAIL
            NSLog(@"bad request error code : %ld", (long)[httpResponse statusCode]);
            completion(nil);
        }
    }];
    [task resume];
}

@end