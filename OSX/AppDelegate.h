//
//  AppDelegate.h
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import "SmallModelView.h"

typedef enum : NSUInteger {
    BLEConnectionStateDisconnected,
    BLEConnectionStateScanning,
    BLEConnectionStateConnected
} BLEConnectionState;

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property IBOutlet NSMenu *statusMenu;
// BLE and DEVICE related
@property (nonatomic) BOOL isBLECapable;
@property (nonatomic) BOOL isBLEEnabled;
@property (nonatomic) BLEConnectionState connectionState;

// STATUS BAR MENU CONTROLS
-(IBAction)toggleOrientationWindow:(id)sender;
-(IBAction)toggleStatusWindow:(id)sender;
-(IBAction)togglePreferencesWindow:(id)sender;
-(IBAction)scanOrEject:(id)sender;
@property IBOutlet NSMenuItem *orientationMenuItem;
@property IBOutlet NSMenuItem *statusMenuItem;
@property IBOutlet NSMenuItem *preferencesMenuItem;
@property IBOutlet NSMenuItem *scanOrEjectMenuItem;

// WINDOWS
@property (assign) IBOutlet NSWindow *orientationWindow;
@property (assign) IBOutlet NSWindow *statusWindow;
@property (assign) IBOutlet NSWindow *preferencesWindow;
@property BOOL orientationWindowVisible;
@property BOOL statusWindowVisible;
@property IBOutlet SmallModelView *smallModelView;

// PREFERENCES WINDOW CONTROLS
-(IBAction)axisInvert:(id)sender;
@property IBOutlet NSTextField *pitchRangeField;
@property IBOutlet NSTextField *rollRangeField;
@property IBOutlet NSTextField *yawRangeField;
@property IBOutlet NSSlider *pitchSlider;
@property IBOutlet NSSlider *rollSlider;
@property IBOutlet NSSlider *yawSlider;
-(IBAction)pitchSliderChange:(id)sender;
-(IBAction)rollSliderChange:(id)sender;
-(IBAction)yawSliderChange:(id)sender;
@property IBOutlet NSSegmentedControl *pitchSegmentedControl;
@property IBOutlet NSSegmentedControl *rollSegmentedControl;
@property IBOutlet NSSegmentedControl *yawSegmentedControl;
-(IBAction)pitchSegmentedChanged:(NSSegmentedControl*)sender;
-(IBAction)rollSegmentedChanged:(NSSegmentedControl*)sender;
-(IBAction)yawSegmentedChanged:(NSSegmentedControl*)sender;

@end
