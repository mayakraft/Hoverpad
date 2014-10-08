//
//  InstructionsView.m
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "StatusView.h"

@implementation StatusView

-(void) setDevicesInRange:(NSDictionary *)devicesInRange{
    NSString *string = @"";
    for(NSDictionary *p in devicesInRange){
        string = [string stringByAppendingString:[NSString stringWithFormat:@"%@ (%@)\n",[p objectForKey:@"name"],[p objectForKey:@"RSSI"]]];
    }
    [_devicesInRangeTextView setString:string];
}

-(void) updateStateCapable:(BOOL)isCapable Enabled:(BOOL)isEnabled Connected:(int)isConnected{
    if(isCapable) [_imageStatus1 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus1 setImage:[NSImage imageNamed:NSImageNameStatusNone]];

    if(isEnabled) [_imageStatus2 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus2 setImage:[NSImage imageNamed:NSImageNameStatusNone]];

    if(isConnected == 0)
        [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusNone]];
    else if(isConnected == 1)
        [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
    else if(isConnected == 2)
        [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
}

@end
