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

+ (void)imageForPost:(NSDictionary *)post completion:(void(^)(UIImage *image))completion
{
    NSString *imageName = post[@"image_url"];
    NSString *urlString = [NSString stringWithFormat:@"http://10.73.45.42:80/%@", imageName];
    
    UIImage *imageFromCache = [[SAMCache sharedCache] imageForKey:imageName];
    if (imageFromCache) {
        completion(imageFromCache);
        return;
    }
    
    NSURL *imageURL = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:imageURL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:urlRequest completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSData *data = [NSData dataWithContentsOfURL:location];
        UIImage *image = [UIImage imageWithData:data];
        [[SAMCache sharedCache] setImage:image forKey:imageName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image);
        });
    }];
    [task resume];
}

@end