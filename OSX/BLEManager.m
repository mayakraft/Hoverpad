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

@interface BLEManager (){
    CBCharacteristic *myReadChar, *myWriteChar, *myNotifyChar;
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;
}
@end

@implementation BLEManager

-(id) initWithDelegate:(id<BLEDelegate>)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
    }
    return self;
}

-(void) boot{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
-(void) startScanAndAutoConnect{
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [_centralManager scanForPeripheralsWithServices:services options:nil];
    [self setConnectionState:BLEConnectionStateScanning];
}
-(void) stopScan{
    [_centralManager stopScan];
    [self setConnectionState:BLEConnectionStateDisconnected];
}

-(void) disconnect{
    [self setConnectionState:BLEConnectionStateDisconnected];
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
            [_centralManager cancelPeripheralConnection:_peripheral];
            _peripheral = nil;
        }
    }
    _connectionState = connectionState;
    [_delegate connectionDidUpdate:connectionState];
}

#pragma mark- DELEGATES - BLE CENTRAL

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"central delegate: didConnectPeripheral: %@", peripheral.name);
    [self setConnectionState:BLEConnectionStateConnected];
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [peripheral discoverServices:services];
    NSLog(@"SERVICES: %@",services);
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
    NSLog(@"central delegate: didDiscoverPeripheral");
    
//    if([self addPeripheralInRangeIfUnique:peripheral RSSI:RSSI])
//        [statusView setDevicesInRange:peripheralsInRange];
    
    //TODO: doesn't clear ghost devices
    
//    if(_peripheral != nil){
//        return;
//    }
    
    NSLog(@"Discovered peripheral: %@",[advertisementData objectForKey:CBAdvertisementDataLocalNameKey]);
    NSLog(@" - with ServiceUUID: %@",[advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey]);
    CBUUID *uuid = [[advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey] firstObject];
    if(uuid == nil) {
        NSLog(@"ATTN: Skipping over a discovered peripheral because it isn't sharing its Advertisment Data with us");
        return;
    }
    NSString *str = [[[NSUUID alloc] initWithUUIDBytes:uuid.data.bytes] UUIDString];
    if([str isEqual:SERVICE_UUID]){
        NSLog(@"Peripheral is in our service!");
        NSLog(@"Peripheral.name: %@",peripheral.name);
        NSLog(@"Peripheral.services: %@",peripheral.services);
        NSLog(@"Peripheral.state: %ld",peripheral.state);
        NSLog(@"advertisementData: %@",advertisementData);
        NSLog(@"RSSI: %@",RSSI);
        
        [self stopScan];
        
        _peripheral = peripheral;
//        [self buildReadWriteNotifyStrings:[[advertisementData objectForKey:CBAdvertisementDataLocalNameKey] substringToIndex:4]];
        [_peripheral setDelegate:self];
        [_centralManager connectPeripheral:_peripheral options:nil];
    }
    else{
        NSLog(@"ATTN: skipping over peripheral, it appears it isn't in our service");
    }
}
-(void) centralManagerDidUpdateState:(CBCentralManager *)central{
    if([central state] == CBCentralManagerStatePoweredOn){
        NSLog(@"central delegate: central powered on");
        [self setIsBluetoothEnabled:YES];
    }
    else if([central state] == CBCentralManagerStateUnsupported ||
            [central state] == CBCentralManagerStatePoweredOff){
        // connection not going to happen
        _centralManager = nil;
    }
    
    if([central state] == CBCentralManagerStatePoweredOff){
        NSLog(@"central delegate: central powered off");
        NSLog(@"probably, bluetooth has been turned off"); // but not certain!
        [self setIsBluetoothEnabled:NO];
    }
    NSLog(@"updating state: %ld",[_centralManager state]);
    [self setHardwareState:[_centralManager state]];
}

#pragma mark- DELEGATES - BLE PERIPHERAL

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"delegate: didDiscoverServices");
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]) {
            NSLog(@"Found our service!");
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"peripheral delegate: didDiscoverCharacteristicForService");
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
            NSLog(@"found our notify characteristic");
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [_delegate characteristicDidUpdate:characteristic.value];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"delegate: didWriteValueForCharacteristic");
}

@end
