//
//  InstructionsView.m
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "StatusView.h"

@implementation StatusView

-(void) setDeviceID:(NSString *)deviceID{
    _deviceID = deviceID;
    [_deviceTextField setStringValue:_deviceID];
}

-(void) setDevicesInRange:(NSDictionary *)devicesInRange{
    NSString *string = @"";
    for(NSDictionary *p in devicesInRange){
        string = [string stringByAppendingString:[NSString stringWithFormat:@"%@ (%@)\n",[p objectForKey:@"name"],[p objectForKey:@"RSSI"]]];
    }
    NSLog(@"STRING: %@",string);
    [_devicesInRangeTextView setString:string];
}

-(void) updateStateCapable:(BOOL)isCapable Enabled:(BOOL)isEnabled Connected:(BOOL)isConnected{
    if(isCapable) [_imageStatus1 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus1 setImage:[NSImage imageNamed:NSImageNameStatusNone]];

    if(isEnabled) [_imageStatus2 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus2 setImage:[NSImage imageNamed:NSImageNameStatusNone]];

    if(isConnected) [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusNone]];
}

@end
