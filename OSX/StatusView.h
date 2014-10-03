//
//  InstructionsView.h
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusView : NSView

-(void) updateStateCapable:(BOOL)isCapable Enabled:(BOOL)isEnabled Connected:(BOOL)isConnected;

@property (nonatomic) NSString *deviceID;

@property IBOutlet NSImageView *imageStatus1;
@property IBOutlet NSImageView *imageStatus2;
@property IBOutlet NSImageView *imageStatus3;

@property IBOutlet NSTextField *deviceTextField;

@property IBOutlet NSTextView *devicesInRangeTextView;

@property (nonatomic) NSArray *devicesInRange;

@end
