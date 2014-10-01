//
//  InstructionsView.m
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "StatusView.h"

@implementation StatusView

-(void) updateStateCapable:(BOOL)isCapable Enabled:(BOOL)isEnabled Connected:(BOOL)isConnected{
    if(isCapable) [_colorWell1 setColor:[NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0]];
    else [_colorWell1 setColor:[NSColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0]];

    if(isEnabled) [_colorWell2 setColor:[NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0]];
    else [_colorWell2 setColor:[NSColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0]];

    if(isConnected) [_colorWell3 setColor:[NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0]];
    else [_colorWell3 setColor:[NSColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0]];
}

@end
