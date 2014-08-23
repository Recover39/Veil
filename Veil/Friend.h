//
//  Friend.h
//  Pine
//
//  Created by soojin on 8/12/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Friend : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSString * sectionIdentifier;
@property (nonatomic, retain) NSNumber * selected;

@end
