//
//  ViewController.h
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "BLEPeripheral.h"
#import <GLKit/GLKit.h>
#import "ScreenView.h"

@interface ViewController : GLKViewController <BLEPeripheralDelegate>{
    CMMotionManager *motionManager;
    GLKQuaternion identity;
    GLKQuaternion lq;
    ScreenView *screenView;
    NSDate *connectionTime;
    BLEPeripheral *blePeripheral;
}

@property (nonatomic) BOOL screenTouched;
@property (nonatomic) BOOL buttonTouched;

@property (nonatomic) NSData *orientation;

@property NSString *UUID;

@end
