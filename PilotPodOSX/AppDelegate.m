//
//  AppDelegate.m
//  PilotPodOSX
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "AppDelegate.h"
#import "View.h"
#import "VHIDDevice.h"
#import <WirtualJoy/WJoyDevice.h>

#define SERVICE_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F30"

#define READ_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F40"
#define WRITE_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F41"
#define NOTIFY_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F42"

@interface AppDelegate() <VHIDDeviceDelegate> {
    CBCentralManager *myCentralManager;
    CBPeripheral *myPeripheral;
    CBCharacteristic *myReadChar, *myWriteChar, *myNotifyChar;
    View *view;
    VHIDDevice *joystickDescription;
    WJoyDevice *virtualJoystick;
}

@end

@implementation AppDelegate

-(void) toggleOrientationWindow:(id)sender{
    BOOL isVisible = [_window isVisible];
    if(isVisible) [_orientationMenuItem setTitle:@"Show Orientation"];
    else [_orientationMenuItem setTitle:@"Hide Orientation"];
    [_window setIsVisible:!isVisible];
    [_window makeKeyAndOrderFront:self];
    //TODO: make key order didn't work
}

-(void) toggleInstructionsWindow:(id)sender{
    BOOL isVisible = [_instructions isVisible];
    if(isVisible) [_instructionsMenuItem setTitle:@"Instructions"];
    else [_instructionsMenuItem setTitle:@"Hide Instructions"];
    [_instructions setIsVisible:!isVisible];
    [_instructions makeKeyAndOrderFront:self];
}


-(void) awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *menuIcon = [NSImage imageNamed:@"Menu Icon"];
    NSImage *highlightIcon = [NSImage imageNamed:@"Menu Icon"];
    
    [statusItem setImage:menuIcon];
    [statusItem setAlternateImage:highlightIcon];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"You do not need this..."];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self performSelector:@selector(initCentral) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(startScan) withObject:nil afterDelay:3.0];
    view = self.window.contentView;
    joystickDescription = [[VHIDDevice alloc] initWithType:VHIDDeviceTypeJoystick pointerCount:6 buttonCount:1 isRelative:NO];
    [joystickDescription setDelegate:self];
    
    virtualJoystick = [[WJoyDevice alloc] initWithHIDDescriptor:[joystickDescription descriptor] productString:@"BLE Joystick"];
//    virtualJoystick = [[WJoyDevice alloc] initWithHIDDescriptor:[joystickDescription descriptor] properties:@{WJoyDeviceProductStringKey : @"iOSVirtualJoystick", WJoyDeviceSerialNumberStringKey : @"556378"}];
}

-(void) something{
    NSPoint newPosition = NSZeroPoint;
    newPosition.y += 0.3025f;
    [joystickDescription setPointer:0 position:newPosition];
}

-(void) VHIDDevice:(VHIDDevice *)device stateChanged:(NSData *)state{
    [virtualJoystick updateHIDState:state];
    NSLog(@"HID state updated");
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

    _deviceConnected = true;
    
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
    if ([characteristic.value length] == 4) {  //([characteristic.value bytes]){
        float q[4];
        [self unpackData:[characteristic value] IntoQuaternionX:&q[0] Y:&q[1] Z:&q[2] W:&q[3]];

        NSPoint newPosition = NSZeroPoint;
        newPosition.x += q[0];
        newPosition.y += q[1];
        [joystickDescription setPointer:0 position:newPosition];

        //TODO: if view is visible
        [view setOrientation:q];
        [view setNeedsDisplay:true];
    }
    else if ([characteristic.value length] == 1) {
        char *touched = (char*)[[characteristic value] bytes];
        BOOL t = *touched;
        [view setScreenTouched:t];
    }
    else{
        
    }
}

-(void) unpackData:(NSData*)receivedData IntoQuaternionX:(float*)x Y:(float*)y Z:(float*)z W:(float*)w {
    char *data = (char*)[receivedData bytes];
    *x = data[0] / 128.0f;
    *y = data[1] / 128.0f;
    *z = data[2] / 128.0f;
    *w = data[3] / 128.0f;
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Wrote value for characteristic!");
}


@end
