//
//  PNCamPreviewView.m
//  Pine
//
//  Created by soojin on 6/27/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "PNCamPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PNCamPreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}
@end
