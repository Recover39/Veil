//
//  UIImage+Scale.m
//  Pine
//
//  Created by soojin on 7/3/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (scale)

- (UIImage *)scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end
