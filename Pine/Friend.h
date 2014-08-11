//
//  Friend.h
//  Pine
//
//  Created by soojin on 8/9/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Friend : NSManagedObject

@property (nonatomic) NSString * name;
@property (nonatomic) NSString * phoneNumber;
@property (nonatomic) NSNumber * selected;

@property (nonatomic, readonly) NSString *sectionIdentifier;

@end
