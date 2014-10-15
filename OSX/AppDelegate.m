//
//  AppDelegate.m
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "AppDelegate.h"
#import <GLKit/GLKit.h>
#import "BLEManager.h"
#import "AnalogStick.h"

// Views
#import "OrientationView.h"
#import "StatusView.h"

#define MAX_AXIS_RANGE 180
#define MIN_AXIS_RANGE 5

#define countingCharacters @"⠀⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿"

@interface AppDelegate() <BLEDelegate> {
    OrientationView *orientationView;
    StatusView *statusView;
//    NSMutableArray *peripheralsInRange;
    NSUInteger scanClock;
    NSTimer *scanClockLoop;
    NSStatusItem *statusItem; // must be member variable, must stick around
    AnalogStick *analogStick;
    BLEManager *bleManager;
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

    [_pitchSlider setIntValue:[analogStick pitchRange]];
    [_rollSlider setIntValue:[analogStick rollRange]];
    [_yawSlider setIntValue:[analogStick yawRange]];
    [_pitchRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick pitchRange]]];
    [_rollRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick rollRange]]];
    [_yawRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick yawRange]]];

    bleManager = [[BLEManager alloc] initWithDelegate:self];
}

#pragma mark- INTERFACE

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
}
-(IBAction)pitchSliderChange:(id)sender{
    if([_pitchSlider integerValue] > MAX_AXIS_RANGE)
        [_pitchSlider setIntValue:MAX_AXIS_RANGE];
    else if([_pitchSlider integerValue] < MIN_AXIS_RANGE)
        [_pitchSlider setIntValue:MIN_AXIS_RANGE];
    [analogStick setPitchRange:(int)[(NSSlider*)sender integerValue]];
    [_smallModelView setPitchAngle:[analogStick pitchRange]];
    [_pitchRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick pitchRange]]];
}
-(IBAction)rollSliderChange:(id)sender{
    if([_rollSlider integerValue] > MAX_AXIS_RANGE)
        [_rollSlider setIntValue:MAX_AXIS_RANGE];
    else if([_rollSlider integerValue] < MIN_AXIS_RANGE)
        [_rollSlider setIntValue:MIN_AXIS_RANGE];
    [analogStick setRollRange:(int)[(NSSlider*)sender integerValue]];
    [_smallModelView setRollAngle:[analogStick rollRange]];
    [_rollRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick rollRange]]];
}
-(IBAction)yawSliderChange:(id)sender{
    if([_yawSlider integerValue] > MAX_AXIS_RANGE)
        [_yawSlider setIntValue:MAX_AXIS_RANGE];
    else if([_yawSlider integerValue] < MIN_AXIS_RANGE)
        [_yawSlider setIntValue:MIN_AXIS_RANGE];
    [analogStick setYawRange:(int)[(NSSlider*)sender integerValue]];
    [_smallModelView setYawAngle:[analogStick yawRange]];
    [_yawRangeField setStringValue:[NSString stringWithFormat:@"%d°",[analogStick yawRange]]];
}
-(IBAction)pitchSegmentedChanged:(NSSegmentedControl*)sender{
    if([sender selectedSegment] == [_yawSegmentedControl selectedSegment]){
        if([_rollSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+1)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+2)%3];
        else if([_rollSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+2)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"fuck up #1");
    }
    else if([sender selectedSegment] == [_rollSegmentedControl selectedSegment]){
        if([_yawSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+1)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+2)%3];
        else if([_yawSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+2)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"fuck up #2");
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
        else NSLog(@"fuck up #1");
    }
    else if([sender selectedSegment] == [_yawSegmentedControl selectedSegment]){
        if([_pitchSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+1)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+2)%3];
        else if([_pitchSegmentedControl selectedSegment] == ([_yawSegmentedControl selectedSegment]+2)%3)
            [_yawSegmentedControl setSelectedSegment:([_yawSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"fuck up #2");
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
        else NSLog(@"fuck up #1");
    }
    else if([sender selectedSegment] == [_rollSegmentedControl selectedSegment]){
        if([_pitchSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+1)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+2)%3];
        else if([_pitchSegmentedControl selectedSegment] == ([_rollSegmentedControl selectedSegment]+2)%3)
            [_rollSegmentedControl setSelectedSegment:([_rollSegmentedControl selectedSegment]+1)%3];
        else NSLog(@"fuck up #2");
    }
    [self updateAxisRoutingToPitch:(int)[_pitchSegmentedControl selectedSegment]
                              Roll:(int)[_rollSegmentedControl selectedSegment]
                               Yaw:(int)[_yawSegmentedControl selectedSegment]];
}
-(void) updateAxisRoutingToPitch:(int)p Roll:(int)r Yaw:(int)y{
    [analogStick setPitchAxis:p];
    [analogStick setRollAxis:r];
    [analogStick setYawAxis:y];
}

#pragma mark- BLE DELEGATES

-(void) BLEBootedAndReady{
    [self bootScanIfPossible];
}
-(void)bootScanIfPossible{
    if([bleManager connectionState] == BLEConnectionStateDisconnected)
        [self startScan];
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
    
    if ([data length] == 4) {  //([characteristic.value bytes]){
        
        [analogStick updateOrientation:data];
        
        if(_orientationWindowVisible){
            [orientationView setOrientation:[analogStick q]];
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

#pragma mark- BLUETOOTH DEVICE CONNECTION

-(void) scanClockLoopFunction{
    if(scanClock >= countingCharacters.length-1){
        [bleManager stopScan];
        return;
    }
    scanClock++;
//    NSLog(@"scanning (%lusec)",(unsigned long)scanClock);
    [_scanOrEjectMenuItem setTitle:[NSString stringWithFormat:@"%@ Scanning",[countingCharacters substringWithRange:NSMakeRange(scanClock, 1)]]];
}
-(void) startScan{
    NSLog(@"startScan");
    scanClock = 0;
    scanClockLoop = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(scanClockLoopFunction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:scanClockLoop forMode:NSRunLoopCommonModes];
    [bleManager startScanAndAutoConnect];
}

@end
