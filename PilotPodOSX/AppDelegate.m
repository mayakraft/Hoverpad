//
//  AppDelegate.m
//  PilotPodOSX
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "AppDelegate.h"
#import "View.h"

#define SERVICE_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F30"

#define READ_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F40"
#define WRITE_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F41"
#define NOTIFY_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F42"

@interface AppDelegate() {
    CBCentralManager *myCentralManager;
    CBPeripheral *myPeripheral;
    CBCharacteristic *myReadChar, *myWriteChar, *myNotifyChar;
    View *view;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self performSelector:@selector(initCentral) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(startScan) withObject:nil afterDelay:3.0];
    view = self.window.contentView;
}

-(void) initCentral{
    NSLog(@"initCentral");
    myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

-(void) startScan{
    NSLog(@"startScan");
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [myCentralManager scanForPeripheralsWithServices:services options:nil];
    [self isLECapableHardware];
}

- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([myCentralManager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    return FALSE;
}

#pragma mark Central delegates

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    NSLog(@"Connected to peripheral %@", peripheral.name);
    
    // Let's qeury the service
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [peripheral discoverServices:services];
    
}

-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    if(myPeripheral != nil){
        return;
    }
    NSLog(@"Discovered peripheral: %@",[advertisementData objectForKey:CBAdvertisementDataLocalNameKey]);
    [myCentralManager stopScan];
    myPeripheral = peripheral;
    myPeripheral.delegate = self;
    
    [myCentralManager connectPeripheral:myPeripheral options:nil];
}

-(void) centralManagerDidUpdateState:(CBCentralManager *)central{
    if(central.state == CBCentralManagerStatePoweredOn){
        NSLog(@"Central powered on");
    }
}



#pragma mark Peripheral Delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Discovered services!");
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]) {
            NSLog(@"Found our service!");
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Discovered characteristics!");
    for (CBCharacteristic* characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_CHAR_UUID]]) {
            myReadChar = characteristic;
            NSLog(@"Found read char!");
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_CHAR_UUID]]) {
            myWriteChar = characteristic;
            NSLog(@"Found write char!");
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID]]) {
            myNotifyChar = characteristic;
            NSLog(@"Found notify char!");
            
            [myPeripheral setNotifyValue:YES forCharacteristic:myNotifyChar];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.value bytes]) {
//        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:characteristic.value];
//        NSLog(@"\n[%.3f, %.3f, %.3f]\n[%.3f, %.3f, %.3f]\n[%.3f, %.3f, %.3f]",
//              [array[0] doubleValue], [array[1] doubleValue], [array[2] doubleValue],
//              [array[3] doubleValue], [array[4] doubleValue], [array[5] doubleValue],
//              [array[6] doubleValue], [array[7] doubleValue], [array[8] doubleValue]);

        [view encodedOrientation:[characteristic value]];
        [view setNeedsDisplay:true];
//        NSLog(@"r: %@",str);
    } else {
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Wrote value for characteristic!");
}


@end
