//
//  ViewController.m
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "ViewController.h"

#ifndef CGRECTRADIAN
#define CGRECTRADIAN
// like CGRectContainsPoint, but with a circle
bool CGRectCircleContainsPoint(CGPoint center, float radius, CGPoint point){
    float dx = center.x - point.x;
    float dy = center.y - point.y;
    return (  radius > sqrtf(powf(dx, 2) + powf(dy, 2) )  );
}
#endif

#define SENSOR_RATE 1.0f/30.0f

@implementation ViewController

-(id) init{
    self = [super init];
    if(self) [self setupContext];
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self) [self setupContext];
    return self;
}
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) [self setupContext];
    return self;
}
-(void) setupContext{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:context];
    screenView = [[ScreenView alloc] initWithFrame:[[UIScreen mainScreen] bounds] context:context];
    [self setView:screenView];
    
    blePeripheral = [[BLEPeripheral alloc] initWithDelegate:self];
    
    _UUID = [self random16bit:4];
    identity = GLKQuaternionIdentity;
    motionManager = [[CMMotionManager alloc] init];
    
    if (motionManager.isDeviceMotionAvailable){
        motionManager.deviceMotionUpdateInterval = SENSOR_RATE;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error){
            
            static const float d = 7;
            CMRotationMatrix m = deviceMotion.attitude.rotationMatrix;
            [screenView setDeviceOrientation:GLKMatrix4MakeLookAt(m.m31*d, m.m32*d, m.m33*d, 0.0f, 0.0f, 0.0f, m.m21, m.m22, m.m23)];

            CMQuaternion q = deviceMotion.attitude.quaternion;
            lq.x = q.x;   lq.y = q.y;   lq.z = q.z;   lq.w = q.w;
            if(_screenTouched){
                identity = GLKQuaternionInvert(lq);
            }
            NSData *newOrientation = [self encodeQuaternion:GLKQuaternionMultiply(identity, lq)];
            if(![_orientation isEqualToData:newOrientation]){
                [self setOrientation:newOrientation];
            }
        }];
    }
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [screenView draw];
}

-(void) setOrientation:(NSData *)orientation{
    _orientation = orientation;
    [blePeripheral broadcastData:orientation];
}

#pragma mark- TOUCHES

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    for(UITouch *touch in touches){
        if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), 30, [touch locationInView:screenView])){
            // button: touch down
            if(!_buttonTouched){
                [self setButtonTouched:YES];
            }
        }
        else if(!_screenTouched){
            [self setScreenTouched:YES];
        }
    }
}
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{ }
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    for(UITouch *touch in touches){
        if(_screenTouched){
            [self setScreenTouched:NO];
        }
        if(_buttonTouched){
            if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), 30, [touch locationInView:screenView])){
            
                // button: touch up
                [self buttonTapped];
            }
            [self setButtonTouched:NO];
        }
    }
}
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"TOUCHES CANCELLED");
}
-(void) setScreenTouched:(BOOL)screenTouched{
    _screenTouched = screenTouched;
    [screenView setIsScreenTouched:screenTouched];
    [blePeripheral sendScreenTouched:screenTouched];
}
-(void) setButtonTouched:(BOOL)buttonTouched{
    _buttonTouched = buttonTouched;
    [screenView setIsButtonTouched:buttonTouched];
}

-(void) stateDidUpdate:(PeripheralConnectionState)state{
    [screenView setState:state];
}

-(void) buttonTapped{
    if([blePeripheral state] == PeripheralConnectionStateDisconnected){
        [blePeripheral setState:PeripheralConnectionStateBooting];
        [blePeripheral initPeripheral];
        connectionTime = [NSDate date];
    }
    else if([blePeripheral state] == PeripheralConnectionStateScanning || [blePeripheral state] == PeripheralConnectionStateConnected){
        [blePeripheral setState:PeripheralConnectionStateDisconnecting];
        [blePeripheral stopAdvertisements];
    }
}

#pragma mark - MATH & DATA

-(NSString*)random16bit:(NSUInteger)numberOfDigits{
    NSString *string = @"";
    for(int i = 0; i < numberOfDigits; i++){
        int number = arc4random()%16;
        if(number > 9){
            char letter = 'A' + number - 10;
            string = [string stringByAppendingString:[NSString stringWithFormat:@"%c",letter]];
        }
        else
            string = [string stringByAppendingString:[NSString stringWithFormat:@"%d",number]];
    }
    return string;
}

-(NSData*) encodeQuaternion:(GLKQuaternion)q{
    // encodes (x,y,z)w quaternion floats into signed char
    // -1.0 to 1.0 into -127 to 127
    char bytes[4];
    short temp;
    temp = q.x * 128.0f;
    bytes[0] = (char)temp;
    bytes[1] = (char)(q.y * 128.0f);
    bytes[2] = (char)(q.z * 128.0f);
    bytes[3] = (char)(q.w * 128.0f);
    return [NSData dataWithBytes:bytes length:4];
}

@end
