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
#define ORIENT_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE34"

@implementation BLEPeripheral

#pragma mark- INIT

-(id) init{
    self = [super init];
    if(self){
        [self buildService];
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
//        NSLog(@" 1 : PERIPHERAL : 1 - INIT");
    }
    return self;
}

-(id) initWithDelegate:(id<BLEPeripheralDelegate>)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
        [self buildService];
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
//        NSLog(@" 1 : PERIPHERAL : 1 - INIT");
    }
    return self;
}
-(id) initWithDelegate:(id<BLEPeripheralDelegate>)delegate WithoutAdvertising:(BOOL)preventAdvertising{
    self = [super init];
    if(self){
        _delegate = delegate;
        [self buildService];
        preventInitialAdvertising = preventAdvertising;
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
//        NSLog(@" 1 : PERIPHERAL : 1 - INIT");
    }
    return self;
}

-(void) buildService{
    readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:READ_CHAR_UUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:WRITE_CHAR_UUID] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:0];
    orientationCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:ORIENT_CHAR_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:0];
    
    service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID] primary:YES];
    service.characteristics = @[readCharacteristic, writeCharacteristic, notifyCharacteristic, orientationCharacteristic];
    
    advertisement = [NSMutableDictionary dictionary];
    [advertisement setObject:[self getName] forKey:CBAdvertisementDataLocalNameKey];
    [advertisement setObject:@[[CBUUID UUIDWithString:SERVICE_UUID]] forKey:CBAdvertisementDataServiceUUIDsKey];
}

#pragma mark- CUSTOM CALLS

-(void)broadcastData:(NSData *)data{
    if(peripheralManager)
        [peripheralManager updateValue:data forCharacteristic:orientationCharacteristic onSubscribedCentrals:nil];
}

-(void) sendDisconnect{
    unsigned char exit[1] = {0x3b};
    if(peripheralManager)
        [peripheralManager updateValue:[NSData dataWithBytes:&exit length:1] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) sendScreenTouched:(BOOL)touched{
    unsigned char d[2] = {0x88,0x00};
    d[1] = (touched ? 1 : 0);
    if(peripheralManager)
        [peripheralManager updateValue:[NSData dataWithBytes:&d length:2] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(NSInteger) hardwareState{
    return [peripheralManager state];
}

-(void) setState:(PeripheralConnectionState)state{
    _state = state;
    [_delegate stateDidUpdate:state];
//    NSLog(@"STATE CHANGE: %d",(int)state);
//    if(state == PeripheralConnectionStateDisconnected);
//    if(state == PeripheralConnectionStateBooting);
//    if(state == PeripheralConnectionStateScanning);
//    if(state == PeripheralConnectionStateScanning);
//    if(state == PeripheralConnectionStateDisconnecting);
}

- (NSString*)getName{
//    return [NSString stringWithFormat:@"Hoverpad (%@)",_UUID];
    return @"Hoverpad";
}

#pragma mark- CORE

- (void)startAdvertisements{
    [peripheralManager startAdvertising:advertisement];
    _isAdvertising = YES;
//    NSLog(@" 3 : PERIPHERAL : 3 - STARTING ADVERTISEMENTS");
}

- (void)stopAdvertisements:(BOOL)disconnectServer{
    
    if(disconnectServer)
        [self sendDisconnect];
    
    [peripheralManager stopAdvertising];
    _isAdvertising = NO;
    
    //TODO: this is happening repeatedly
    [self setState:PeripheralConnectionStateDisconnected];
}

#pragma mark- DELEGATES - PERIPHERAL

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
//    NSLog(@" 1b: PERIPHERAL : 1b- INIT DELEGATE RESPONSE");
    [_delegate hardwareStateDidUpdate:[peripheralManager state]];
    if([peripheralManager state] == CBPeripheralManagerStatePoweredOn){
        [peripheralManager addService:service];
//        NSLog(@" 2 : PERIPHERAL : 2 - SERVICES ADDED");
    }
    else if ([peripheralManager state] == CBPeripheralManagerStateUnsupported){
//        NSLog(@"WARNING: Bluetooth LE Unsupported");
    }
    else if([peripheralManager state] == CBPeripheralManagerStateUnauthorized){
//        NSLog(@"WARNING: Bluetooth LE Unauthorized");
    }
    else if([peripheralManager state] == CBPeripheralManagerStateResetting){
//        NSLog(@"WARNING: Bluetooth LE State Resetting");
    }
    else if([peripheralManager state] == CBPeripheralManagerStateUnknown){
//        NSLog(@"WARNING: Bluetooth LE State Unknown");
    }
    else if([peripheralManager state] == CBPeripheralManagerStatePoweredOff){
//        NSLog(@"WARNING: Bluetooth LE Manager Powered Off");
    }
}

-(void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
//    NSLog(@" 2b: PERIPHERAL : 2b- SERVICES ADDED DELEGATE RESPONSE");
    // TODO HANDLE ERROR
    if(!preventInitialAdvertising)
        [self startAdvertisements];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
//    NSLog(@" 3b: PERIPHERAL : 3b- STARTING ADVERTISEMENTS DELEGATE RESPONSE");
    // TODO HANDLE ERROR
    [self setState:PeripheralConnectionStateScanning];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
//    NSLog(@"delegate: received write request");
    for(CBATTRequest* request in requests) {
        if([request.value bytes]){
//            NSLog(@"WE RECEIVED INFO: %@",[request value]);
            if([[request value] length] == 2){
                unsigned char *msg = (unsigned char*)[[request value] bytes];
                if (msg[0] == 0x8F){ // version code
                    if(msg[1] == 0x01){  // release version 1
//                        NSLog(@"VERSION 1 SUCCESSFULLY RECEIVED");
                    }
                }
            }
            if([[request value] length] == 1){
//            unsigned char exit[2] = {0x3b};
            }
        }
        [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
//    NSLog(@"delegate: received read request");
//    NSString *valueToSend;
//    NSDate *currentTime = [NSDate date];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"hh:mm:ss"];
//    valueToSend = [dateFormatter stringFromDate: currentTime];
//    
//    request.value = [valueToSend dataUsingEncoding:NSASCIIStringEncoding];
//    
//    [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
//    NSLog(@"delegate: Central subscribed to characteristic:%@",[characteristic UUID]);
    if(_state != PeripheralConnectionStateConnected)
        [self setState:PeripheralConnectionStateConnected];
}
-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
//    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
//    NSLog(@"delegate: Central unsubscribed!");
    if([self state] != PeripheralConnectionStateDisconnected){
//        [self setState:PeripheralConnectionStateDisconnected];
        [self stopAdvertisements:NO]; // this sets the disconnected state
    }
}

@end
