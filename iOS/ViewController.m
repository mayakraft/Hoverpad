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
        if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), BUTTON_RADIUS, [touch locationInView:screenView])){
            // button: touch down
            if(!_buttonTouched){
                [self setButtonTouched:YES];
            }
        }
        else if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.9, [[UIScreen mainScreen] bounds].size.height*.5), 40, [touch locationInView:screenView])){
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
            if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), BUTTON_RADIUS, [touch locationInView:screenView])){
            
                // button: touch up
                [self buttonTapped];
            }
            [self setButtonTouched:NO];
        }
        if(CGRectCircleContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.9, [[UIScreen mainScreen] bounds].size.height*.5), 40, [touch locationInView:screenView])){
//            [self settingsButtonPress:nil];
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
    if(settingsView)
        [settingsView setConnectionState:state];
}

-(void) buttonTapped{
    if([blePeripheral state] == PeripheralConnectionStateDisconnected){
        [blePeripheral setState:PeripheralConnectionStateBooting];
        [blePeripheral initPeripheral];
        connectionTime = [NSDate date];
    }
    else if([blePeripheral state] == PeripheralConnectionStateScanning || [blePeripheral state] == PeripheralConnectionStateConnected){
        [blePeripheral setState:PeripheralConnectionStateDisconnecting];
        [blePeripheral stopAdvertisements:NO];
    }
}

-(void)settingsButtonPress:(id)sender{
    settingsView = [[SettingsView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStyleGrouped];
    [settingsView setDataSource:settingsView];
    [settingsView setClipsToBounds:NO];
    [settingsView setDelegate:self];
    [settingsView setBackgroundColor:[UIColor clearColor]];
    [settingsView setBackgroundView:nil];
    [settingsView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [settingsView setSeparatorInset:UIEdgeInsetsZero];
    [settingsView setCenter:CGPointMake(settingsView.center.x+settingsView.bounds.size.width, settingsView.center.y)];
    settingsView.sectionHeaderHeight = 1.0;
    settingsView.sectionFooterHeight = 1.0;
    [settingsView setConnectionState:[blePeripheral state]];
    [self.view addSubview:settingsView];

    CGRect oldframe = settingsView.frame;
    settingsView.transform=CGAffineTransformMakeRotation(M_PI/2);
    // For some weird reason, the frame of the table also gets rotated, so you must restore the original frame
    settingsView.frame = oldframe;
    
//    [self performSelector:@selector(expandToCollapse:) withObject:@"settings"];
//    //    [self performSelector:@selector(expandToCollapse:) withObject:@"playground" afterDelay:0.1];
//    [self performSelector:@selector(expandToCollapse:) withObject:@"generator" afterDelay:0.1];  //.2
    [self animateSettingsTableIn];
}

-(void) animateSettingsTableIn
{
    [UIView beginAnimations:@"animateSettingsTableIn" context:nil];
    [UIView setAnimationDuration:.33];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [settingsView setCenter:self.view.center];
    [UIView commitAnimations];
}
-(void) animateSettingsTableOut
{
    [UIView beginAnimations:@"animateSettingsTableIn" context:nil];
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

#pragma mark- SETTINGS TABLE DELEGATE

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section{
    if(section == 0)
        return 40.0f;
    return 1.0f;
}
- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section{
    return 1.0;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0)
        return 46;
    if(indexPath.section == 0)
        return 100;
    else if(indexPath.section == 1)
        return 120;
    else if (indexPath.section == 2)
        return 360;
    return 400;
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
    else if(indexPath.section == 0){
//      [cell.detailTextLabel setText:@"no"];
    }
    else if (indexPath.section == 1){
        if([blePeripheral state] == PeripheralConnectionStateDisconnected){
            [self buttonTapped];
            [self animateSettingsTableOut];
        }
    }
    else if (indexPath.section == 2){
    }
    else if (indexPath.section == 3){
//        if([cell.detailTextLabel.text isEqualToString:@"b&w"])
//            [[NSUserDefaults standardUserDefaults] setObject:@"clay" forKey:@"theme"];
//        else if([cell.detailTextLabel.text isEqualToString:@"clay"])
//            [[NSUserDefaults standardUserDefaults] setObject:@"ice" forKey:@"theme"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        [self updateColorsProgramWide];
//        [tableView reloadData];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
