//
//  TMPComment.h
//  Pine
//
//  Created by soojin on 7/15/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMPComment : NSObject

@property (nonatomic, retain) NSNumber *commentID;
@property (nonatomic, retain) NSNumber *commentType;
@property (nonatomic, retain) NSNumber *commenterID;
@property (nonatomic, retain) NSNumber *likeCount;
@property (strong, nonatomic) NSNumber *userLiked;
@property (nonatomic, retain) NSDate *publishedDate;
@property (nonatomic, retain) NSString *content;

@end
