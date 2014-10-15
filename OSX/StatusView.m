//
//  InstructionsView.m
//
//  Created by Robby on 9/30/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "StatusView.h"

@implementation StatusView

-(void) setStatusMessage:(NSString *)statusMessage{
    _statusMessage = statusMessage;
    [_statusTextField setStringValue:statusMessage];
}

//-(void) setDevicesInRange:(NSDictionary *)devicesInRange{
//    NSString *string = @"";
//    for(NSDictionary *p in devicesInRange){
//        string = [string stringByAppendingString:[NSString stringWithFormat:@"%@ (%@)\n",[p objectForKey:@"name"],[p objectForKey:@"RSSI"]]];
//    }
//    [_devicesInRangeTextView setString:string];
//}

-(void) updateBluetoothEnabled:(NSUInteger)enabled{
    if(enabled) [_imageStatus2 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus2 setImage:[NSImage imageNamed:NSImageNameStatusNone]];
}
-(void) updateBLECapable:(NSUInteger)enabled{
    if(enabled) [_imageStatus1 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    else [_imageStatus1 setImage:[NSImage imageNamed:NSImageNameStatusNone]];
}
-(void) updateDeviceConnected:(NSUInteger)enabled{
    if(enabled == 0)
        [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusNone]];
    else if(enabled == 1)
        [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
    else if(enabled == 2)
        [_imageStatus3 setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
}

@end
