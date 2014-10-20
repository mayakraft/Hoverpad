//
//  AppDelegate.m
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "AppDelegate.h"
#import "BLEManager.h"
#import "AnalogStick.h"
// Views
#import "OrientationView.h"
#import "StatusView.h"

#define MAX_AXIS_RANGE 180
#define MIN_AXIS_RANGE 5

#define countingCharacters @"⠀⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿"

@interface AppDelegate() <BLEDelegate> {
    AnalogStick *analogStick;
    BLEManager *bleManager;
    OrientationView *orientationView;
    StatusView *statusView;
    NSUInteger scanClock;
    NSTimer *scanClockLoop;
    NSStatusItem *statusItem; // must be member variable, must stick around
}

@end

@implementation AppDelegate

-(void) awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *menuIcon = [NSImage imageNamed:@"Menu Icon"];
    NSImage *highlightIcon = [NSImage imageNamed:@"Menu Icon"];
    [statusItem setImage:menuIcon];
    [statusItem setAlternateImage:highlightIcon];
    [statusItem setMenu:_statusMenu];
    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"Hoverpad"];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    
    orientationView = _orientationWindow.contentView;
    statusView = _statusWindow.contentView;
    
    NSButton *closeButton = [_orientationWindow standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(toggleOrientationWindow:)];
    NSButton *closeStatus = [_statusWindow standardWindowButton:NSWindowCloseButton];
    [closeStatus setTarget:self];
    [closeStatus setAction:@selector(toggleStatusWindow:)];

    analogStick = [[AnalogStick alloc] init];
    
    [self setupUserDefaults]; // after analogStick alloc

    bleManager = [[BLEManager alloc] initWithDelegate:self];
}

-(void) setupUserDefaults{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"axisMap"] == nil){
        NSDictionary *axisMap = @{@"pitch" : @0, @"roll" : @1, @"yaw" : @2 };
        [[NSUserDefaults standardUserDefaults] setObject:axisMap forKey:@"axisMap"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        [analogStick setPitchAxis:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisMap"] objectForKey:@"pitch"] intValue]];
        [analogStick setRollAxis:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisMap"] objectForKey:@"roll"] intValue]];
        [analogStick setYawAxis:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisMap"] objectForKey:@"yaw"] intValue]];
    }
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] == nil){
        NSDictionary *axisRange = @{@"pitch" : @90, @"roll" : @90, @"yaw" : @90 };
        [[NSUserDefaults standardUserDefaults] setObject:axisRange forKey:@"axisRange"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        [analogStick setPitchRange:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] objectForKey:@"pitch"] intValue]];
        [analogStick setRollRange:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] objectForKey:@"roll"] intValue]];
        [analogStick setYawRange:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] objectForKey:@"yaw"] intValue]];
    }
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"axisInvert"] == nil){
        NSDictionary *axisInvert = @{@"pitch" : @NO, @"roll" : @NO, @"yaw" : @NO };
        [[NSUserDefaults standardUserDefaults] setObject:axisInvert forKey:@"axisInvert"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        [analogStick setInvertPitch:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisInvert"] objectForKey:@"pitch"] boolValue]];
        [analogStick setInvertRoll:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisInvert"] objectForKey:@"roll"] boolValue]];
        [analogStick setInvertYaw:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"axisInvert"] objectForKey:@"yaw"] boolValue]];
    }
    [_pitchRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick pitchRange]]];
    [_rollRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick rollRange]]];
    [_yawRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick yawRange]]];
    [_pitchSegmentedControl setSelectedSegment:[analogStick pitchAxis]];
    [_rollSegmentedControl setSelectedSegment:[analogStick rollAxis]];
    [_yawSegmentedControl setSelectedSegment:[analogStick yawAxis]];
    [_smallModelView setPitchAngle:[analogStick pitchRange]];
    [_smallModelView setRollAngle:[analogStick rollRange]];
    [_smallModelView setYawAngle:[analogStick yawRange]];
    [_pitchInvertButton setState:[analogStick invertPitch]];
    [_rollInvertButton setState:[analogStick invertRoll]];
    [_yawInvertButton setState:[analogStick invertYaw]];
    [_pitchSlider setIntValue:[analogStick pitchRange]];
    [_rollSlider setIntValue:[analogStick rollRange]];
    [_yawSlider setIntValue:[analogStick yawRange]];
}

-(void)bootScanIfPossible{
    if([bleManager connectionState] == BLEConnectionStateDisconnected)
        [self startScan];
}
-(void) scanClockLoopFunction{
    if(scanClock >= countingCharacters.length-1){
        [bleManager stopScan];
        return;
    }
    scanClock++;
    [_scanOrEjectMenuItem setTitle:[NSString stringWithFormat:@"%@ Scanning",[countingCharacters substringWithRange:NSMakeRange(scanClock, 1)]]];
}
-(void) startScan{
//    NSLog(@"startScan");
    scanClock = 0;
    scanClockLoop = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(scanClockLoopFunction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:scanClockLoop forMode:NSRunLoopCommonModes];
    [bleManager startScanAndAutoConnect];
}

#pragma mark- BLE DELEGATES

-(void) BLEBootedAndReady{
    [self bootScanIfPossible];
}
-(void) bluetoothStateDidUpdate:(BOOL)enabled{
    if(!enabled)
        [statusView setStatusMessage:@"bluetooth is off"];
    [statusView updateBluetoothEnabled:enabled];
}
-(void) hardwareDidUpdate:(BLEHardwareState)state{
    BOOL capable = false;
    if(state == BLEHardwareStatePoweredOn){
        capable = true;
    }
    else if(state == BLEHardwareStateUnsupported){
        [statusView setStatusMessage:@"Your computer doesn't have Bluetooth Low Energy"];
    }
    else if(state == BLEHardwareStateUnauthorized){
        [statusView setStatusMessage:@"The app is asking for permission to use Bluetooth Low Energy"];
    }
    else if (state == BLEHardwareStatePoweredOff) {
        [statusView setStatusMessage:@"Turn on Bluetooth Low Energy and try again"];
    }
    else {
        [statusView setStatusMessage:@"Bluetooth status unknown"];
    }
    [statusView updateBLECapable:capable];
}
-(void) connectionDidUpdate:(BLEConnectionState)state{
    if(state == BLEConnectionStateDisconnected){
        // if we just disconnected from a device
        if(scanClockLoop == nil){
            [statusView setStatusMessage:[NSString stringWithFormat:@"disconnected from hoverpad"]];//%@",[_peripheral name]]];
        }
        // if scanning ended unsuccessfully
        else if(scanClockLoop){
            [scanClockLoop invalidate];
            scanClockLoop = nil;
            [statusView setStatusMessage:@"nothing in range"];
        }
        else if(![bleManager isBluetoothEnabled]){
            [statusView setStatusMessage:@"bluetooth is off"];
        }
        else {
            [statusView setStatusMessage:@"nothing in range"];
        }
        [analogStick destroyVirtualJoystick];
        [orientationView setDeviceIsConnected:NO];
        [_scanOrEjectMenuItem setImage:[NSImage imageNamed:NSImageNameRefreshTemplate]];
        [_scanOrEjectMenuItem setTitle:@"Scan"];
        [_scanOrEjectMenuItem setEnabled:YES];
        [statusView updateDeviceConnected:0];
    }
    else if(state == BLEConnectionStateScanning){
        [statusView setStatusMessage:@"searching for a connection.."];
        [_scanOrEjectMenuItem setImage:nil];
        [_scanOrEjectMenuItem setTitle:[NSString stringWithFormat:@"%@ Scanning",[countingCharacters substringWithRange:NSMakeRange(0, 1)]]];
        [statusView updateDeviceConnected:1];
    }
    else if(state == BLEConnectionStateConnected){
        if(scanClockLoop){
            [scanClockLoop invalidate];
            scanClockLoop = nil;
        }
        [analogStick createVirtualJoystick];
        [orientationView setDeviceIsConnected:YES];
        [statusView setStatusMessage:[NSString stringWithFormat:@"connected to hoverpad"]];//%@",[_peripheral name]]];
        [_scanOrEjectMenuItem setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
        [_scanOrEjectMenuItem setTitle:@"Disconnect"];
        [_scanOrEjectMenuItem setEnabled:YES];
        [statusView updateDeviceConnected:2];
    }
}
-(void) characteristicDidUpdate:(NSData *)data{
    //TODO: Clarify packet language
    if ([data length] == 4) {  //([characteristic.value bytes]){
        [analogStick updateOrientation:data];
        if(_orientationWindowVisible){
            [orientationView setOrientationMatrix:[analogStick m]];
            [orientationView setNeedsDisplay:true];
        }
    }
    else if ([data length] == 1) {
        char *touched = (char*)[data bytes];
        BOOL t = *touched;
        [orientationView setScreenTouched:t];
    }
    else if ([data length] == 2){
        char *msg = (char*)[data bytes];
        if (*msg == 0x3b){ // exit code
            [bleManager disconnect];
        }
    }
}

#pragma mark- INTERFACE
-(void) programExit{
    [[NSApplication sharedApplication] terminate:self];
}
-(IBAction)quit:(id)sender{
    if([bleManager connectionState] == BLEConnectionStateConnected){
        [bleManager disconnect];
        NSLog(@"disconnecting");
        [self performSelector:@selector(programExit) withObject:nil afterDelay:0.2];
    }
    else{
        [self programExit];
    }
}
-(IBAction)scanOrEject:(id)sender{
    if([bleManager connectionState] == BLEConnectionStateDisconnected){
        if([bleManager isBluetoothEnabled])
            [self startScan];
        else{
            // bluetooth wasn't enabled before
            // try again from the beginning
            [bleManager softReset];
            [statusView setStatusMessage:@"booting up.."];
        }
    }
    else if([bleManager connectionState] == BLEConnectionStateScanning){ }
    else if([bleManager connectionState] == BLEConnectionStateConnected){
        [bleManager disconnect];
    }
}
-(IBAction) togglePreferencesWindow:(id)sender{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [_preferencesWindow makeKeyAndOrderFront:self];
}
-(IBAction) toggleOrientationWindow:(id)sender{
    if(_orientationWindowVisible){
        [_orientationMenuItem setTitle:@"Show Orientation"];
        [_orientationWindow close];
    }
    else{
        [_orientationMenuItem setTitle:@"Hide Orientation"];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [_orientationWindow makeKeyAndOrderFront:self];
    }
    _orientationWindowVisible = !_orientationWindowVisible;
}
-(IBAction) toggleStatusWindow:(id)sender{
    if(_statusWindowVisible){
        [_statusMenuItem setTitle:@"Show Status"];
        [_statusWindow close];
    }
    else{
        [_statusMenuItem setTitle:@"Hide Status"];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [_statusWindow makeKeyAndOrderFront:self];
    }
    _statusWindowVisible = !_statusWindowVisible;
}
-(IBAction)axisInvert:(id)sender{
    if([sender tag] == 1)
        [analogStick setInvertPitch:[(NSButton*)sender state]];
    else if([sender tag] == 2)
        [analogStick setInvertRoll:[(NSButton*)sender state]];
    else if([sender tag] == 3)
        [analogStick setInvertYaw:[(NSButton*)sender state]];

    NSDictionary *axisInvert = @{@"pitch" : [NSNumber numberWithBool:[analogStick invertPitch]],
                                 @"roll" : [NSNumber numberWithBool:[analogStick invertRoll]],
                                 @"yaw" : [NSNumber numberWithBool:[analogStick invertYaw]] };
    [[NSUserDefaults standardUserDefaults] setObject:axisInvert forKey:@"axisInvert"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}
-(IBAction)pitchSliderChange:(id)sender{
    if([_pitchSlider integerValue] > MAX_AXIS_RANGE)
        [_pitchSlider setIntValue:MAX_AXIS_RANGE];
    else if([_pitchSlider integerValue] < MIN_AXIS_RANGE)
        [_pitchSlider setIntValue:MIN_AXIS_RANGE];
    [analogStick setPitchRange:(int)[(NSSlider*)sender integerValue]];
    [_smallModelView setPitchAngle:[analogStick pitchRange]];
    [_pitchRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick pitchRange]]];
    NSMutableDictionary *axisRange = [[[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] mutableCopy];
    [axisRange setObject:[NSNumber numberWithInt:[analogStick pitchRange]] forKey:@"pitch"];
    [[NSUserDefaults standardUserDefaults] setObject:axisRange forKey:@"axisRange"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(IBAction)rollSliderChange:(id)sender{
    if([_rollSlider integerValue] > MAX_AXIS_RANGE)
        [_rollSlider setIntValue:MAX_AXIS_RANGE];
    else if([_rollSlider integerValue] < MIN_AXIS_RANGE)
        [_rollSlider setIntValue:MIN_AXIS_RANGE];
    [analogStick setRollRange:(int)[(NSSlider*)sender integerValue]];
    [_smallModelView setRollAngle:[analogStick rollRange]];
    [_rollRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick rollRange]]];
    NSMutableDictionary *axisRange = [[[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] mutableCopy];
    [axisRange setObject:[NSNumber numberWithInt:[analogStick rollRange]] forKey:@"roll"];
    [[NSUserDefaults standardUserDefaults] setObject:axisRange forKey:@"axisRange"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(IBAction)yawSliderChange:(id)sender{
    if([_yawSlider integerValue] > MAX_AXIS_RANGE)
        [_yawSlider setIntValue:MAX_AXIS_RANGE];
    else if([_yawSlider integerValue] < MIN_AXIS_RANGE)
        [_yawSlider setIntValue:MIN_AXIS_RANGE];
    [analogStick setYawRange:(int)[(NSSlider*)sender integerValue]];
    [_smallModelView setYawAngle:[analogStick yawRange]];
    [_yawRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick yawRange]]];
    NSMutableDictionary *axisRange = [[[NSUserDefaults standardUserDefaults] objectForKey:@"axisRange"] mutableCopy];
    [axisRange setObject:[NSNumber numberWithInt:[analogStick yawRange]] forKey:@"yaw"];
    [[NSUserDefaults standardUserDefaults] setObject:axisRange forKey:@"axisRange"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(IBAction)pitchSegmentedChanged:(NSSegmentedControl*)sender{
    if([sender selectedSegment] == [_yawSegmentedControl selectedSegment]){
        if([_rollSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+1)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+2)%3];
        else if([_rollSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+2)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"logic fuck up #1");
    }
    else if([sender selectedSegment] == [_rollSegmentedControl selectedSegment]){
        if([_yawSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+1)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+2)%3];
        else if([_yawSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+2)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"logic fuck up #2");
    }
    [self updateAxisRoutingToPitch:(int)[_pitchSegmentedControl selectedSegment]
                              Roll:(int)[_rollSegmentedControl selectedSegment]
                               Yaw:(int)[_yawSegmentedControl selectedSegment]];
}
-(IBAction)rollSegmentedChanged:(NSSegmentedControl*)sender{
    if([sender selectedSegment] == [_pitchSegmentedControl selectedSegment]){
        if([_yawSegmentedControl selectedSegment] == ([_pitchSegmentedControl selectedSegment]+1)%3)
            [_pitchSegmentedControl setSelectedSegment:([_pitchSegmentedControl selectedSegment]+2)%3];
        else if([_yawSegmentedControl selectedSegment] == ([_pitchSegmentedControl selectedSegment]+2)%3)
            [_pitchSegmentedControl setSelectedSegment:([_pitchSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"logic fuck up #3");
    }
    else if([sender selectedSegment] == [_yawSegmentedControl selectedSegment]){
        if([_pitchSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+1)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+2)%3];
        else if([_pitchSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+2)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"logic fuck up #4");
    }
    [self updateAxisRoutingToPitch:(int)[_pitchSegmentedControl selectedSegment]
                              Roll:(int)[_rollSegmentedControl selectedSegment]
                               Yaw:(int)[_yawSegmentedControl selectedSegment]];
}
-(IBAction)yawSegmentedChanged:(NSSegmentedControl*)sender{
    if([sender selectedSegment] == [_pitchSegmentedControl selectedSegment]){
        if([_rollSegmentedControl selectedSegment] == ([_pitchSegmentedControl selectedSegment]+1)%3)
            [_pitchSegmentedControl setSelectedSegment:([_pitchSegmentedControl selectedSegment]+2)%3];
        else if([_rollSegmentedControl selectedSegment] == ([_pitchSegmentedControl selectedSegment]+2)%3)
            [_pitchSegmentedControl setSelectedSegment:([_pitchSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"logic fuck up #5");
    }
    else if([sender selectedSegment] == [_rollSegmentedControl selectedSegment]){
        if([_pitchSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+1)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+2)%3];
        else if([_pitchSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+2)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"logic fuck up #6");
    }
    [self updateAxisRoutingToPitch:(int)[_pitchSegmentedControl selectedSegment]
                              Roll:(int)[_rollSegmentedControl selectedSegment]
                               Yaw:(int)[_yawSegmentedControl selectedSegment]];
}
-(void) updateAxisRoutingToPitch:(int)p Roll:(int)r Yaw:(int)y{
    [analogStick setPitchAxis:p];
    [analogStick setRollAxis:r];
    [analogStick setYawAxis:y];
    NSDictionary *axisMap = @{@"pitch" : [NSNumber numberWithInt:p], @"roll" : [NSNumber numberWithInt:r], @"yaw" : [NSNumber numberWithInt:y] };
    [[NSUserDefaults standardUserDefaults] setObject:axisMap forKey:@"axisMap"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
