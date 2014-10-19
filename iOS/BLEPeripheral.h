//
//  BLEPeripheral.h
//  Hoverpad
//
//  Created by Robby on 10/15/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum : NSUInteger {
    PeripheralConnectionStateDisconnected,
    PeripheralConnectionStateBooting,
    PeripheralConnectionStateScanning,
    PeripheralConnectionStateConnected,
    PeripheralConnectionStateDisconnecting
} PeripheralConnectionState;

@protocol BLEPeripheralDelegate <NSObject>
@optional
-(void) stateDidUpdate:(PeripheralConnectionState)state;
@end

@interface BLEPeripheral : NSObject <CBPeripheralManagerDelegate>{
    CBPeripheralManager *peripheralManager;
    CBMutableCharacteristic *readCharacteristic, *writeCharacteristic, *notifyCharacteristic;
}

@property id <BLEPeripheralDelegate> delegate;
@property (nonatomic) PeripheralConnectionState state;

-(id) initWithDelegate:(id<BLEPeripheralDelegate>)delegate;

-(void) broadcastData:(NSData*)data;
-(void) initPeripheral;
-(void) startAdvertisements;
-(void) stopAdvertisements:(BOOL)serverAlreadyDisconnected;

-(void) sendScreenTouched:(BOOL)touched;

@end
