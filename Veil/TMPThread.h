//
//  TMPThread.h
//  Pine
//
//  Created by soojin on 7/7/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PNThreadType) {
    PNThreadTypeNormal = 0,
    PNThreadTypeSelf = 1
};

@interface TMPThread : NSObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSDate * publishedDate;
@property (nonatomic, retain) NSNumber * threadID;
@property (nonatomic, retain) NSNumber * userLiked;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSNumber * type;

@end