//
//  InstructionsView.h
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusView : NSView

@property IBOutlet NSImageView *imageStatus1;
@property IBOutlet NSImageView *imageStatus2;
@property IBOutlet NSImageView *imageStatus3;
@property IBOutlet NSTextField *statusTextField;

// set this, message will appear on status window
@property (nonatomic) NSString *statusMessage;

// update light sequence
-(void) updateStateCapable:(BOOL)isCapable Enabled:(BOOL)isEnabled Connected:(int)isConnected;

@end