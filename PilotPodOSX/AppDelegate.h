//
//  AppDelegate.h
//  PilotPodOSX
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

-(IBAction)toggleOrientationWindow:(id)sender;
-(IBAction)toggleInstructionsWindow:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *instructions;

@property IBOutlet NSMenuItem *orientationMenuItem;
@property IBOutlet NSMenuItem *instructionsMenuItem;

@end
