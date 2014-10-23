//
//  BLEManager.m
//  Hoverpad
//
//  Created by Robby on 10/15/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "BLEManager.h"

#define SERVICE_UUID     @"2166E780-4A62-11E4-817C-0002A5D5DE30"
#define READ_CHAR_UUID   @"2166E780-4A62-11E4-817C-0002A5D5DE31"
#define WRITE_CHAR_UUID  @"2166E780-4A62-11E4-817C-0002A5D5DE32"
#define NOTIFY_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE33"
#define ORIENT_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE34"

@interface BLEManager (){
    CBCharacteristic *myReadChar, *myWriteChar, *myNotifyChar, *orientationCharacteristic;
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;
}
@end

@implementation BLEManager

// all these muthafuckin delegate functions with these ERROR handlers, CHECK THE ERRORS, why don't you, before trying to get at the data stuff


//    [_peripheral readValueForCharacteristic:<#(CBCharacteristic *)#>]; - calls did update value for characteristic

-(id) init{
    self = [super init];
    if(self){
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
    return self;
}

-(id) initWithDelegate:(id<BLEDelegate>)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
        NSLog(@"  1 : CENTRAL MANAGER SETUP : 1");
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
    return self;
}

-(void) startScanAndAutoConnect{
    [self setConnectionState:BLEConnectionStateScanning];
}
-(void) stopScan{
    [_centralManager stopScan];
    NSLog(@"╚════ SCAN STOP");
    [self setConnectionState:BLEConnectionStateDisconnected];
}

-(void) disconnect{
    [self setConnectionState:BLEConnectionStateDisconnected];
}

-(void) softReset{
    _peripheral = nil;
    _centralManager = nil;
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
}

-(void) setHardwareState:(BLEHardwareState)hardwareState{
    _hardwareState = hardwareState;
    [_delegate hardwareDidUpdate:hardwareState];
    if(_hardwareState == BLEHardwareStatePoweredOn)
        [_delegate BLEBootedAndReady];
}

-(void)setIsBluetoothEnabled:(BOOL)isBluetoothEnabled{
    _isBluetoothEnabled = isBluetoothEnabled;
    // if disabled, disconnect all other connections
    if(!isBluetoothEnabled){
        [self setConnectionState:BLEConnectionStateDisconnected];
    }
    [_delegate bluetoothStateDidUpdate:isBluetoothEnabled];
}

-(void) setConnectionState:(BLEConnectionState)connectionState{
    if(connectionState == BLEConnectionStateDisconnected){
        if(_peripheral){
            if(_peripheral)
                [_peripheral setNotifyValue:NO forCharacteristic:myNotifyChar];
            if(_centralManager)
                [_centralManager cancelPeripheralConnection:_peripheral];
            _peripheral = nil;
        }
    }
    if(connectionState == BLEConnectionStateScanning){
        NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
        NSLog(@"  2 : CENTRAL MANAGER SETUP : 2");
        [_centralManager scanForPeripheralsWithServices:services options:nil];
        NSLog(@"╔════ SCAN BEGIN");
    }
    _connectionState = connectionState;
    [_delegate connectionDidUpdate:connectionState];
}

//-(void) sendDataToPeripheral{
//    unsigned char exit[2] = {0x3b};  // exit code
//    NSData *data = [[NSData alloc] initWithBytes:exit length:2];
//    [_peripheral writeValue:data forCharacteristic:myWriteChar type:CBCharacteristicWriteWithResponse];
//}

#pragma mark- DELEGATES - BLE CENTRAL

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self disconnect];
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"  3b: CENTRAL MANAGER SETUP :3b DELEGATE RESPONSE connected:%@", peripheral.name);
    [self setConnectionState:BLEConnectionStateConnected];
    [_peripheral setDelegate:self];
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [peripheral discoverServices:services];
    NSLog(@"  4 : CENTRAL MANAGER SETUP : 4");
//    NSLog(@"SERVICES: %@",services);
}
-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"central did fail to connect to peripheral");
    //TODO: should we re-start scan?
}
//-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
//    [self setConnectionState:BLEConnectionStateDisconnected];
//    NSLog(@"successfully disconnected peripheral %@",[peripheral name]);
//}
-(void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals{
    NSLog(@"did retrieve peripherals:\n%@",peripherals);
}
-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"║ 2b: CENTRAL MANAGER SETUP :2b: DELEGATE RESPONSE");
//    NSLog(@"central delegate: didDiscoverPeripheral");
//    NSLog(@"Discovered peripheral: %@",[advertisementData objectForKey:CBAdvertisementDataLocalNameKey]);
//    NSLog(@" - with ServiceUUID: %@",[advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey]);
    CBUUID *uuid = [[advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey] firstObject];
    if(uuid == nil) {
        NSLog(@"ATTN: Skipping over a discovered peripheral because it isn't sharing its Advertisment Data with us");
        return;
    }
    NSString *str = [[[NSUUID alloc] initWithUUIDBytes:uuid.data.bytes] UUIDString];
    if([str isEqual:SERVICE_UUID]){
//        NSLog(@"Peripheral is in our service!");
//        NSLog(@"Peripheral.name: %@",peripheral.name);
//        NSLog(@"Peripheral.services: %@",peripheral.services);
//        NSLog(@"Peripheral.state: %ld",peripheral.state);
//        NSLog(@"advertisementData: %@",advertisementData);
//        NSLog(@"RSSI: %@",RSSI);
        
        [self stopScan];
        
        _peripheral = peripheral;
//        [self buildReadWriteNotifyStrings:[[advertisementData objectForKey:CBAdvertisementDataLocalNameKey] substringToIndex:4]];
        [_centralManager connectPeripheral:_peripheral options:nil];
        NSLog(@"  3 : CENTRAL MANAGER SETUP : 3");
    }
    else{
        NSLog(@"ATTN: skipping over peripheral, it appears it isn't in our service");
    }
}
-(void) centralManagerDidUpdateState:(CBCentralManager *)central{
    if([central state] == CBCentralManagerStatePoweredOn){
        NSLog(@"  1b: CENTRAL MANAGER SETUP :1b: DELEGATE RESPONSE");
        [self setIsBluetoothEnabled:YES];
    }
    else if([central state] == CBCentralManagerStateUnsupported ||
            [central state] == CBCentralManagerStatePoweredOff){
        // connection not going to happen
        _centralManager = nil;
    }
    
    if([central state] == CBCentralManagerStatePoweredOff){
//        NSLog(@"central delegate: central powered off");
//        NSLog(@"probably, bluetooth has been turned off"); // but not certain!
        [self setIsBluetoothEnabled:NO];
    }
    [self setHardwareState:(BLEHardwareState)[_centralManager state]];
}

#pragma mark- DELEGATES - BLE PERIPHERAL

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
//    NSLog(@"delegate: didDiscoverServices");
    NSLog(@"  4b: CENTRAL MANAGER SETUP :4b: DELEGATE RESPONSE");
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]) {
//            NSLog(@"found our service");
            //TODO: do not pass nil for characteristic
            [peripheral discoverCharacteristics:nil forService:service];
            NSLog(@"  5 : CENTRAL MANAGER SETUP : 5");
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"  5b: CENTRAL MANAGER SETUP :5b: DELEGATE RESPONSE");
//    NSLog(@"peripheral delegate: didDiscoverCharacteristicForService");
    for (CBCharacteristic* characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_CHAR_UUID]]) {
            myReadChar = characteristic;
            NSLog(@"found our read characteristic");
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_CHAR_UUID]]) {
            myWriteChar = characteristic;
            NSLog(@"found our write characteristic");
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID]]) {
            myNotifyChar = characteristic;
            [_peripheral setNotifyValue:YES forCharacteristic:myNotifyChar];
            NSLog(@"  6 : CENTRAL MANAGER SETUP : 6");
            NSLog(@"found our notify characteristic");
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ORIENT_CHAR_UUID]]) {
            orientationCharacteristic = characteristic;
            [_peripheral setNotifyValue:YES forCharacteristic:orientationCharacteristic];
            NSLog(@"  6 : CENTRAL MANAGER SETUP : 6");
            NSLog(@"found our orientation characteristic");
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //first, check if there is an error. do not proceed
    //TODO: ask what characteristic this is
//    if([characteristic.UUID.UUIDString isEqualToString:ORIENT_CHAR_UUID])
        [_delegate characteristicDidUpdate:characteristic.value];
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"  6b: CENTRAL MANAGER SETUP :6b: DELEGATE RESPONSE %@",characteristic.UUID);
    // if there's an error, do something
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"delegate: didWriteValueForCharacteristic");
}

@end
