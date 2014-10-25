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

//typedef enum : NSUInteger { /* meant to mimic CBPeripheralManagerState */
//    BLEHardwareStateUnknown,
//    BLEHardwareStateResetting,
//    BLEHardwareStateUnsupported,
//    BLEHardwareStateUnauthorized,
//    BLEHardwareStatePoweredOff,
//    BLEHardwareStatePoweredOn // the only one which should allow code to progress
//} BLEHardwareState;

@protocol BLEPeripheralDelegate <NSObject>
@optional
-(void) stateDidUpdate:(PeripheralConnectionState)state;
@end

@interface BLEPeripheral : NSObject <CBPeripheralManagerDelegate>{
    CBPeripheralManager *peripheralManager;
    CBMutableService *service;
    CBMutableCharacteristic *readCharacteristic, *writeCharacteristic, *notifyCharacteristic, *orientationCharacteristic;
    NSMutableDictionary *advertisement;
    BOOL preventInitialAdvertising;
}

@property id <BLEPeripheralDelegate> delegate;
@property (nonatomic) PeripheralConnectionState state;

-(id) initWithDelegate:(id<BLEPeripheralDelegate>)delegate;
-(id) initWithDelegate:(id<BLEPeripheralDelegate>)delegate WithoutAdvertising:(BOOL)preventAdvertising;

-(void) broadcastData:(NSData*)data;

// advertising
@property (readonly) BOOL isAdvertising;
-(void) startAdvertisements;
-(void) stopAdvertisements:(BOOL)serverAlreadyDisconnected;

-(void) sendScreenTouched:(BOOL)touched;

@end
