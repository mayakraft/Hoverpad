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
#define BUTTON_RADIUS 70

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
    _screenView = [[ScreenView alloc] initWithFrame:[[UIScreen mainScreen] bounds] context:context];
    [self setView:_screenView];
    
    identity = GLKQuaternionIdentity;
    motionManager = [[CMMotionManager alloc] init];
    
    if (motionManager.isDeviceMotionAvailable){
        motionManager.deviceMotionUpdateInterval = SENSOR_RATE;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler:^(CMDeviceMotion *deviceMotion, NSError *error){
            static const float d = 7;
            GLKQuaternion q;
//            static GLKQuaternion identity = GLKQuaternionIdentity;
            CMRotationMatrix m = deviceMotion.attitude.rotationMatrix;
            [_screenView setDeviceOrientation:GLKMatrix4MakeLookAt(m.m31*d, m.m32*d, m.m33*d, 0.0f, 0.0f, 0.0f, m.m21, m.m22, m.m23)];
            // typecasting double to float
            q.x = deviceMotion.attitude.quaternion.x;
            q.y = deviceMotion.attitude.quaternion.y;
            q.z = deviceMotion.attitude.quaternion.z;
            q.w = deviceMotion.attitude.quaternion.w;
            if(_screenTouched){
                identity = GLKQuaternionInvert(q);
            }
            NSData *newOrientation = [self encodeQuaternion:GLKQuaternionMultiply(identity, q)];
            if(![_orientation isEqualToData:newOrientation]){
                [self setOrientation:newOrientation];
            }
        }];
    }

    // first run-time instruction assistance
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"FIRSTBOOT"]){
        [self settingsButtonPress:@YES];
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"FIRSTBOOT"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        blePeripheral = [[BLEPeripheral alloc] initWithDelegate:self WithoutAdvertising:YES];
    }
    else
        blePeripheral = [[BLEPeripheral alloc] initWithDelegate:self];
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [_screenView draw];
}

-(void) setOrientation:(NSData *)orientation{
    _orientation = orientation;
    if([blePeripheral isAdvertising])
        [blePeripheral broadcastData:_orientation];
    if(settingsView && [blePeripheral state] == PeripheralConnectionStateConnected)
        [settingsView flashCommunicationLight];
}

-(void) stateDidUpdate:(PeripheralConnectionState)state{
    [_screenView setState:state];
    if(settingsView)
        [settingsView setConnectionState:state];
}

#pragma mark- TOUCHES

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    for(UITouch *touch in touches){
        if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), BUTTON_RADIUS, [touch locationInView:self.view])){
            // button: touch down
            if(!_buttonTouched){
                [self setButtonTouched:YES];
            }
        }
        else if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.9, [[UIScreen mainScreen] bounds].size.height*.5), 40, [touch locationInView:self.view])){
            [self settingsButtonPress:nil];
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
            if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), BUTTON_RADIUS, [touch locationInView:self.view])){
            
                // button: touch up
                [self buttonTapped];
            }
            [self setButtonTouched:NO];
        }
        if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.9, [[UIScreen mainScreen] bounds].size.height*.5), 40, [touch locationInView:self.view])){
//            [self settingsButtonPress:nil];
        }
    }
}
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"TOUCHES CANCELLED");
}
-(void) setScreenTouched:(BOOL)screenTouched{
    _screenTouched = screenTouched;
    [_screenView setIsScreenTouched:screenTouched];
    [blePeripheral sendScreenTouched:screenTouched];
}
-(void) setButtonTouched:(BOOL)buttonTouched{
    _buttonTouched = buttonTouched;
    [_screenView setIsButtonTouched:buttonTouched];
}
-(void) buttonTapped{
    if([blePeripheral state] == PeripheralConnectionStateDisconnected){
        [blePeripheral setState:PeripheralConnectionStateBooting];
        [blePeripheral startAdvertisements];
    }
    else if([blePeripheral state] == PeripheralConnectionStateScanning || [blePeripheral state] == PeripheralConnectionStateConnected){
        [blePeripheral setState:PeripheralConnectionStateDisconnecting];
        [blePeripheral stopAdvertisements:YES];
    }
}

#pragma mark - MATH & DATA

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

#pragma mark- SETTINGS TABLE

-(void)settingsButtonPress:(NSNumber*)openWelcomeScreen{
    settingsView = [[SettingsView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStyleGrouped];
    [settingsView setCenter:CGPointMake(settingsView.center.x+settingsView.bounds.size.width, settingsView.center.y)];
    [settingsView setConnectionState:[blePeripheral state]];
    [settingsView setDelegate:self];
    [self.view addSubview:settingsView];
    CGRect oldframe = settingsView.frame;
    settingsView.transform=CGAffineTransformMakeRotation(M_PI/2);
    // For some weird reason, the frame of the table also gets rotated, so you must restore the original frame
    settingsView.frame = oldframe;
    [self animateSettingsTableIn:openWelcomeScreen];
}

-(void) animateSettingsTableIn:(NSNumber*)openWelcomeScreen{
    [UIView beginAnimations:@"animateSettingsTableIn" context:nil];
    [UIView setAnimationDuration:.33];
    [UIView setAnimationDelegate:self];
    if(openWelcomeScreen && [openWelcomeScreen boolValue])
        [UIView setAnimationDidStopSelector:@selector(triggerWelcomeScreen)];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [settingsView setCenter:self.view.center];
    [UIView commitAnimations];
}
-(void) triggerWelcomeScreen{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [settingsView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [settingsView.delegate tableView:settingsView didSelectRowAtIndexPath:indexPath];
}
-(void) animateSettingsTableOut{
    [UIView beginAnimations:@"animateSettingsTableOut" context:nil];
    [UIView setAnimationDidStopSelector:@selector(deallocTableView)];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [settingsView setCenter:CGPointMake(self.view.center.x-self.view.bounds.size.height, self.view.center.y)];
    [UIView commitAnimations];
}
-(void) deallocTableView{
    [settingsView removeFromSuperview];
    [settingsView fakeDealloc];
    settingsView = nil;
}

#pragma mark- SETTINGS TABLE DELEGATE

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section{
    if(section == 0)
        return 40.0f + 36*IS_IPAD();
    return 1.0f;
}
- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section{
    return 1.0 + 2*IS_IPAD();
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0)
        return 46 + 76*IS_IPAD();
    if(indexPath.section == 0)
        return 360 + 360*1.7*IS_IPAD();
    else if(indexPath.section == 1)
        return 120 + 120*1.7*IS_IPAD();
    else if (indexPath.section == 2)
        return 400 + 400*1.7*IS_IPAD();
    else if (indexPath.section == 3)
        return 500 + 500*1.7*IS_IPAD();
    return 100 + 100*1.7*IS_IPAD();
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if(indexPath.section == 4){
        [self animateSettingsTableOut];
    }
    else if(indexPath.row == 0){
        settingsView.cellExpanded[indexPath.section] = !settingsView.cellExpanded[indexPath.section];
        if(settingsView.cellExpanded[indexPath.section])
            [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
        else
            [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationTop];
        [tableView beginUpdates];
        [tableView endUpdates];
    }
    else if (indexPath.section == 1){
        if([blePeripheral state] == PeripheralConnectionStateDisconnected){
            [self buttonTapped];
            [self animateSettingsTableOut];
        }
    }
    if(indexPath.row == 1 && (indexPath.section == 0 || indexPath.section == 2 || indexPath.section == 3) )
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
