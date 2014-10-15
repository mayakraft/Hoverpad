//
//  BLEManager.h
//  Hoverpad
//
//  Created by Robby on 10/15/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

typedef enum : NSUInteger {
    BLEConnectionStateDisconnected,
    BLEConnectionStateScanning,
    BLEConnectionStateConnected
} BLEConnectionState;

typedef enum : NSUInteger { /* meant to mimic CBCentralManagerState */
    BLEHardwareStateUnknown,
    BLEHardwareStateResetting,
    BLEHardwareStateUnsupported,
    BLEHardwareStateUnauthorized,
    BLEHardwareStatePoweredOff,
    BLEHardwareStatePoweredOn // the only one which should allow code to progress
} BLEHardwareState;

@protocol BLEDelegate <NSObject>
@required
-(void) characteristicDidUpdate:(NSData*)data;

@optional
-(void) BLEBootedAndReady;  // convenience response to -(void)boot, also happens when BLEHardwareState == PoweredOn
-(void) bluetoothStateDidUpdate:(BOOL)enabled;
-(void) hardwareDidUpdate:(BLEHardwareState)state; // of course, hardware doesn't change- AWARENESS of hardware did
-(void) connectionDidUpdate:(BLEConnectionState)state;
@end

/**
 * @class BLEManager
 * @author Robby Kraft
 * @date 10/15/14
 *
 * @availability iOS (7.0 and later)
 *
 * @discussion a simplified implementation of Bluetooth low energy limiting communication under only one characteristic between two devices
 */
@interface BLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, readonly) BOOL isBluetoothEnabled;
@property (nonatomic, readonly) BLEHardwareState hardwareState;
@property (nonatomic, readonly) BLEConnectionState connectionState;

-(void) boot;
-(void) startScanAndAutoConnect;
-(void) stopScan;
-(void) disconnect;

@property id <BLEDelegate> delegate;

-(id) initWithDelegate:(id<BLEDelegate>)delegate;

@end
