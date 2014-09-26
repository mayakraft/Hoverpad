//
//  ViewController.h
//  PilotPod
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController : UIViewController <CBPeripheralManagerDelegate>
{
    CBPeripheralManager *myPeripheralManager;
    CBMutableCharacteristic *myReadChar, *myWriteChar, *myNotifyChar;
    CMMotionManager *motionManager;
}
@property UIButton *theButton;
@property UITextField *uuid;

@end
