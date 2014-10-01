//
//  AppDelegate.h
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>{
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
    NSImage *statusImage;
    NSImage *statusHighlightImage;
}

// WINDOWS

-(IBAction)toggleOrientationWindow:(id)sender;
-(IBAction)toggleStatusWindow:(id)sender;
@property (assign) IBOutlet NSWindow *orientationWindow;
@property (assign) IBOutlet NSWindow *statusWindow;
@property IBOutlet NSMenuItem *orientationMenuItem;
@property IBOutlet NSMenuItem *statusMenuItem;
@property BOOL orientationWindowVisible;
@property BOOL statusWindowVisible;

// BLE and DEVICE related

@property (nonatomic) BOOL isDeviceConnected;
@property (nonatomic) BOOL isBLEEnabled;
@property (nonatomic) BOOL isBLECapable;

@end
