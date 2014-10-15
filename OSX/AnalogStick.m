//
//  AnalogStick.m
//  Hoverpad
//
//  Created by Robby on 10/15/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "AnalogStick.h"

#import "VHIDDevice.h"
#import <WirtualJoy/WJoyDevice.h>

@interface AnalogStick () <VHIDDeviceDelegate>{
    VHIDDevice *joystickDescription;
    WJoyDevice *virtualJoystick;
}

@end

@implementation AnalogStick

-(id) init{
    self = [super init];
    if(self){
        _pitchAxis = 0;
        _rollAxis = 1;
        _yawAxis = 2;
        _pitchRange = 90;
        _rollRange = 90;
        _yawRange = 90;
        _q = malloc(sizeof(float)*4);
        _m = malloc(sizeof(float)*9);
    }
    return self;
}

-(void) createVirtualJoystick{
    joystickDescription = [[VHIDDevice alloc] initWithType:VHIDDeviceTypeJoystick pointerCount:4 buttonCount:1 isRelative:NO];
    [joystickDescription setDelegate:self];
    NSLog(@"%@",[joystickDescription descriptor]);
//    virtualJoystick = [[WJoyDevice alloc] initWithHIDDescriptor:[joystickDescription descriptor] productString:@"BLE Joystick"];
    virtualJoystick = [[WJoyDevice alloc] initWithHIDDescriptor:[joystickDescription descriptor] properties:
                       @{WJoyDeviceProductStringKey : @"iOSVirtualJoystick",
                         WJoyDeviceSerialNumberStringKey : @"556378",
                         WJoyDeviceVendorIDKey : [NSNumber numberWithUnsignedInt:1133],
                         WJoyDeviceProductIDKey : [NSNumber numberWithUnsignedInt:512]}];
    
}
-(void) destroyVirtualJoystick{
    joystickDescription.delegate = nil;
    joystickDescription = nil;
    virtualJoystick = nil;
}
-(void) VHIDDevice:(VHIDDevice *)device stateChanged:(NSData *)state{
    if(virtualJoystick)
        [virtualJoystick updateHIDState:state];
}
-(void) updateOrientation:(NSData *)data{
    
    static const float halfpi = M_PI*.5;
    
    [self unpackData:data IntoQuaternionX:&_q[0] Y:&_q[1] Z:&_q[2] W:&_q[3]];
    
    _m[0] = 1 - 2*_q[1]*_q[1] - 2*_q[2]*_q[2];   _m[3] = 2*_q[0]*_q[1] - 2*_q[2]*_q[3];       _m[6] = 2*_q[0]*_q[2] + 2*_q[1]*_q[3];
    _m[1] = 2*_q[0]*_q[1] + 2*_q[2]*_q[3];       _m[4] = 1 - 2*_q[0]*_q[0] - 2*_q[2]*_q[2];   _m[7] = 2*_q[1]*_q[2] - 2*_q[0]*_q[3];
    _m[2] = 2*_q[0]*_q[2] - 2*_q[1]*_q[3];       _m[5] = 2*_q[1]*_q[2] + 2*_q[0]*_q[3];       _m[8] = 1 - 2*_q[0]*_q[0] - 2*_q[1]*_q[1];

    int pD = _invertPitch ? -1 : 1;
    int rD = _invertRoll ? -1 : 1;
    int yD = _invertYaw ? -1 : 1;
    float yaw =   yD * atan2f(_m[3], sqrtf(powf(_m[4],2) + powf(_m[5],2) ) );
    float roll = rD * -atan2f(_m[5], sqrtf(powf(_m[3],2) + powf(_m[4],2) ) );
    float pitch = pD * atan2f(_m[2], sqrtf(powf(_m[5],2) + powf(_m[8],2) ) );

    pitch /= halfpi;
    roll /= halfpi;
    yaw /= halfpi;
    
    [self cropPitch:&pitch Roll:&roll Yaw:&yaw];
    
    float axis[3];
    axis[_pitchAxis] = pitch;
    axis[_rollAxis] = roll;
    axis[_yawAxis] = yaw;
    
    [joystickDescription setPointer:0 position:CGPointMake(axis[0], axis[1])];
    [joystickDescription setPointer:1 position:CGPointMake(axis[2], 0)];
//    [joystickDescription setPointer:2 position:CGPointMake(0, 0)];
}

-(void) cropPitch:(float*)pitch Roll:(float*)roll Yaw:(float*)yaw{
    *pitch /= (_pitchRange/180.0);
    if(*pitch > 1.0) *pitch = 1.0;
    *roll /= (_rollRange/180.0);
    if(*roll > 1.0) *roll = 1.0;
    *yaw /= (_yawRange/180.0);
    if(*yaw > 1.0) *yaw = 1.0;
}

-(void) unpackData:(NSData*)receivedData IntoQuaternionX:(float*)x Y:(float*)y Z:(float*)z W:(float*)w {
    char *data = (char*)[receivedData bytes];
    *x = data[0] / 128.0f;
    *y = data[1] / 128.0f;
    *z = data[2] / 128.0f;
    *w = data[3] / 128.0f;
}

-(void) dealloc{
    free(_q);
    free(_m);
}

@end
