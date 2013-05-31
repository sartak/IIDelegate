//
//  IIViewController.m
//  LeakTest
//
//  Created by Shawn M Moore on H.25/05/31.
//  Copyright (c) 平成25年 Infinity Interactive. All rights reserved.
//

#import "IIViewController.h"
#import "IIDelegate.h"

@implementation IIViewController

-(void) runTest:(NSTimer *)timer {
    @autoreleasepool {
        for (int i = 0; i < 100; ++i) {
            [IIDelegate delegateForProtocol:@protocol(UIAlertViewDelegate) withMethods:@{}];
        }
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(runTest:) userInfo:nil repeats:YES];
}

@end
