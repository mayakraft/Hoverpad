//
//  AnalogStick.h
//  Hoverpad
//
//  Created by Robby on 10/15/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalogStick : NSObject

-(void) updateOrientation:(NSData*)encodedData;

-(void) createVirtualJoystick;
-(void) destroyVirtualJoystick;

// orientation
@property float *q; // array[4] (quaternion)
@property float *m; // array[9] (orientation matrix)

@property int pitchAxis;
@property int rollAxis;
@property int yawAxis;

@property BOOL invertPitch;
@property BOOL invertRoll;
@property BOOL invertYaw;

@property int pitchRange;
@property int rollRange;
@property int yawRange;

@end
