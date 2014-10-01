//
//  InstructionsView.m
//  PilotPod
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "InstructionsView.h"

@implementation InstructionsView


-(void) awakeFromNib{
    NSLog(@"instructions loaded");
    [_colorWell1 setColor:[NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0]];
}
@end
