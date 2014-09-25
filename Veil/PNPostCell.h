//
//  PNPostCellTableViewCell.h
//  Pine
//
//  Created by soojin on 6/23/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PNThread.h"
#import "PNCellProtocol.h"
#import "PNThreadActionDelegate.h"

@interface PNPostCell : UITableViewCell <PNCellProtocol>

@property (weak, nonatomic) id<PNThreadActionDelegate> delegate;

@end
