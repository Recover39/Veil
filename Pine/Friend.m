//
//  Friend.m
//  Pine
//
//  Created by soojin on 8/9/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "Friend.h"

@interface Friend()

@property (nonatomic) NSNumber *primitiveSelected;
@property (nonatomic) NSString *primitiveSectionIdentifier;

@end

@implementation Friend

@dynamic name;
@dynamic phoneNumber;
@dynamic selected;
@dynamic primitiveSelected;
@dynamic primitiveSectionIdentifier;

- (NSString *)sectionIdentifier
{
    [self willAccessValueForKey:@"sectionIdentifier"];
    NSString *tmp = [self primitiveSectionIdentifier];
    [self didAccessValueForKey:@"sectionIdentifier"];
    
    if (!tmp) {
        if (self.selected) {
            tmp = @"선택된 사람들";
        } else {
            tmp = @"연락처 사람들";
        }
        
        [self setPrimitiveSectionIdentifier:tmp];
    }
    return tmp;
}

- (void)setSelected:(NSNumber *)selected
{
    //If selected changes, selected identifier is invalid
    [self willAccessValueForKey:@"selected"];
    [self setPrimitiveSelected:selected];
    [self didChangeValueForKey:@"selected"];
    
    [self setPrimitiveSectionIdentifier:nil];
}

+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier
{
    return [NSSet setWithObject:@"selected"];
}

@end
