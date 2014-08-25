//
//  PNCamPreviewView.h
//  Pine
//
//  Created by soojin on 6/27/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface PNCamPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
