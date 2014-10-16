//
//  BLEPeripheral.m
//  Hoverpad
//
//  Created by Robby on 10/15/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "BLEPeripheral.h"

#define SERVICE_UUID     @"2166E780-4A62-11E4-817C-0002A5D5DE30"
#define READ_CHAR_UUID   @"2166E780-4A62-11E4-817C-0002A5D5DE31"
#define WRITE_CHAR_UUID  @"2166E780-4A62-11E4-817C-0002A5D5DE32"
#define NOTIFY_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE33"

@implementation BLEPeripheral

-(id) initWithDelegate:(id<BLEPeripheralDelegate>)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
    }
    return self;
}

#pragma mark- BLUETOOTH LOW ENERGY

-(void)broadcastData:(NSData *)data{
    [peripheralManager updateValue:data forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) sendDisconnect{
    unsigned char exit[2] = {0x3b};
    [peripheralManager updateValue:[NSData dataWithBytes:&exit length:2] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) sendScreenTouched:(BOOL)touched{
    unsigned char d = (touched ? 1 : 0);
    [peripheralManager updateValue:[NSData dataWithBytes:&d length:1] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) setState:(PeripheralConnectionState)state{
    _state = state;
    [_delegate stateDidUpdate:state];
    NSLog(@"STATE CHANGE: %d",(int)state);
//    if(state == PeripheralConnectionStateDisconnected);
//    if(state == PeripheralConnectionStateBooting);
//    if(state == PeripheralConnectionStateScanning);
//    if(state == PeripheralConnectionStateScanning);
//    if(state == PeripheralConnectionStateDisconnecting);
}
- (void)initPeripheral{
    NSLog(@"initPeripheral");
    
    readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:READ_CHAR_UUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:WRITE_CHAR_UUID] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:0];
    
    peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (NSString*)getName{
//    return [NSString stringWithFormat:@"Hoverpad (%@)",_UUID];
    return @"Hoverpad";
}

- (void)startAdvertisements{
    NSLog(@"Starting advertisements...");
    
    NSMutableDictionary *advertisingDict = [NSMutableDictionary dictionary];
    [advertisingDict setObject:[self getName] forKey:CBAdvertisementDataLocalNameKey];
    [advertisingDict setObject:@[[CBUUID UUIDWithString:SERVICE_UUID]] forKey:CBAdvertisementDataServiceUUIDsKey];
    [peripheralManager startAdvertising:advertisingDict];
}

- (void)stopAdvertisements{
    NSLog(@"Stopping advertisements...");
    
    [self sendDisconnect];
    
    [peripheralManager stopAdvertising];
    [peripheralManager removeAllServices];
    peripheralManager = nil;
    
    NSLog(@"Advertisements stopped!");
    [self setState:PeripheralConnectionStateDisconnected];
}

-(CBMutableService*) constructService:(NSString*)ServiceUUID{
    NSLog(@"construct service");
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID] primary:YES];
    
    NSMutableArray *characteristics = [NSMutableArray array];
    [characteristics addObject:readCharacteristic];
    [characteristics addObject:writeCharacteristic];
    [characteristics addObject:notifyCharacteristic];
    service.characteristics = characteristics;
    
    return service;
}

#pragma mark- DELEGATES - PERIPHERAL

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    if([peripheralManager state] == CBPeripheralManagerStatePoweredOn){
        NSLog(@"delegate: peripheral manager powered on");
        
        [peripheralManager addService:[self constructService:SERVICE_UUID]];
        
#pragma mark auto start advertisements
        [self startAdvertisements];
        
    }
    else{
        NSLog(@"delegate: Peripheral state changed to %d", (int)[peripheralManager state]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"delegate: Advertisements started!");
    [self setState:PeripheralConnectionStateScanning];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"delegate: received write request");
    for(CBATTRequest* request in requests) {
//        if ([request.value bytes]) {
//            self.receivedText.text = [[NSString alloc ] initWithBytes:[request.value bytes] length:request.value.length encoding:NSASCIIStringEncoding];
//        } else {
//            self.receivedText.text = @"";
//        }
        [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"delegate: received read request");
    NSString *valueToSend;
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm:ss"];
    valueToSend = [dateFormatter stringFromDate: currentTime];
    
    request.value = [valueToSend dataUsingEncoding:NSASCIIStringEncoding];
    
    [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"delegate: Central subscribed!");
    [self setState:PeripheralConnectionStateConnected];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"delegate: Central unsubscribed!");
    [self setState:PeripheralConnectionStateScanning];
}

@end
