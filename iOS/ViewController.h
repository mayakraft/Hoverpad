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
#import "ScreenView.h"

typedef enum : NSUInteger {
    PeripheralConnectionStateDisconnected,
    PeripheralConnectionStateBooting,
    PeripheralConnectionStateScanning,
    PeripheralConnectionStateConnected,
    PeripheralConnectionStateDisconnecting
} PeripheralConnectionState;


@interface ViewController : GLKViewController <CBPeripheralManagerDelegate>{
    CBPeripheralManager *peripheralManager;
    CBMutableCharacteristic *readCharacteristic, *writeCharacteristic, *notifyCharacteristic;
    CMMotionManager *motionManager;
    GLKQuaternion identity;
    GLKQuaternion lq;
    ScreenView *screenView;
    CGPoint screenCenter;
    NSDate *connectionTime;
}

@property (nonatomic) BOOL screenTouched;
@property (nonatomic) BOOL buttonTouched;

@property (nonatomic) PeripheralConnectionState state;

@property (nonatomic) NSData *orientation;

@property NSString *UUID;

@end
