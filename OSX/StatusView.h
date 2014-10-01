//
//  InstructionsView.h
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusView : NSView

-(void) updateStateCapable:(BOOL)isCapable Enabled:(BOOL)isEnabled Connected:(BOOL)isConnected;

@property IBOutlet NSColorWell *colorWell1;
@property IBOutlet NSColorWell *colorWell2;
@property IBOutlet NSColorWell *colorWell3;
@property IBOutlet NSColorWell *colorWell4;

@end
