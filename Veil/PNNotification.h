//
//  PNNotification.h
//  Veil
//
//  Created by soojin on 8/24/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PNNotification : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * isRead;
@property (nonatomic, retain) NSNumber * threadID;
@property (nonatomic, retain) NSString * imageURL;

@end
