//
//  ViewController.h
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

@interface ViewController : UIViewController <CBPeripheralManagerDelegate>
{
    CBPeripheralManager *myPeripheralManager;
    CBMutableCharacteristic *myReadChar, *myWriteChar, *myNotifyChar;
    CMMotionManager *motionManager;
    
    BOOL screenTouched;
    GLKQuaternion identity;
    GLKQuaternion lq;
}

@property (nonatomic) NSData *orientation;
@property UIButton *theButton;

//@property UITextField *uuid;

@end
