//
//  AppDelegate.m
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "AppDelegate.h"
#import "VHIDDevice.h"
#import <WirtualJoy/WJoyDevice.h>
#import <GLKit/GLKit.h>

// NSViews
#import "View.h"
#import "StatusView.h"

#define SERVICE_UUID     @"2166E780-4A62-11E4-817C-0002A5D5DE30"
#define READ_CHAR_UUID   @"2166E780-4A62-11E4-817C-0002A5D5DE31"
#define WRITE_CHAR_UUID  @"2166E780-4A62-11E4-817C-0002A5D5DE32"
#define NOTIFY_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE33"

#define MAX_AXIS_RANGE 180
#define MIN_AXIS_RANGE 5

#define countingCharacters @"⠀⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿"

@interface AppDelegate() <VHIDDeviceDelegate> {
    CBCharacteristic *myReadChar, *myWriteChar, *myNotifyChar;
    VHIDDevice *joystickDescription;
    WJoyDevice *virtualJoystick;
    View *orientationView;
    StatusView *statusView;
    NSMutableArray *peripheralsInRange;
    NSUInteger scanClock;
    NSTimer *scanClockLoop;
    BOOL invertPitch, invertRoll, invertYaw;
    int pitchRange, rollRange, yawRange;
}

@property CBCentralManager *centralManager;
@property CBPeripheral *peripheral;

@end

@implementation AppDelegate

-(void) awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *menuIcon = [NSImage imageNamed:@"Menu Icon"];
    NSImage *highlightIcon = [NSImage imageNamed:@"Menu Icon"];
    [statusItem setImage:menuIcon];
    [statusItem setAlternateImage:highlightIcon];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"Hoverpad"];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    
    orientationView = _orientationWindow.contentView;
    statusView = _statusWindow.contentView;
    
    NSButton *closeButton = [_orientationWindow standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(toggleOrientationWindow:)];
    NSButton *closeStatus = [_statusWindow standardWindowButton:NSWindowCloseButton];
    [closeStatus setTarget:self];
    [closeStatus setAction:@selector(toggleStatusWindow:)];
    
    peripheralsInRange = [NSMutableArray array];
    
    pitchRange = 90;
    rollRange = 90;
    yawRange = 90;
    [_pitchSlider setIntValue:pitchRange];
    [_rollSlider setIntValue:rollRange];
    [_yawSlider setIntValue:yawRange];
    
    [self preferencesDidUpdate];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark- INTERFACE

-(IBAction)scanOrEject:(id)sender{
    if(_connectionState == BLEConnectionStateDisconnected){
        if(_isBLECapable)
            [self setConnectionState:BLEConnectionStateScanning];
        else{
            // bluetooth wasn't enabled before
            // try again from the beginning
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
    }
    else if(_connectionState == BLEConnectionStateScanning){ }
    else if(_connectionState == BLEConnectionStateConnected){
        [self setConnectionState:BLEConnectionStateDisconnected];
    }
}
-(IBAction) togglePreferencesWindow:(id)sender{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [_preferencesWindow makeKeyAndOrderFront:self];
}
-(IBAction) toggleOrientationWindow:(id)sender{
    if(_orientationWindowVisible){
        [_orientationMenuItem setTitle:@"Show Orientation"];
        [_orientationWindow close];
    }
    else{
        [_orientationMenuItem setTitle:@"Hide Orientation"];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [_orientationWindow makeKeyAndOrderFront:self];
    }
    _orientationWindowVisible = !_orientationWindowVisible;
}
-(IBAction) toggleStatusWindow:(id)sender{
    if(_statusWindowVisible){
        [_statusMenuItem setTitle:@"Show Status"];
        [_statusWindow close];
    }
    else{
        [_statusMenuItem setTitle:@"Hide Status"];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [_statusWindow makeKeyAndOrderFront:self];
    }
    _statusWindowVisible = !_statusWindowVisible;
}
-(IBAction)axisInvert:(id)sender{
    if([sender tag] == 1)
        invertPitch = [(NSButton*)sender state];
    else if([sender tag] == 2)
        invertRoll = [(NSButton*)sender state];
    else if([sender tag] == 3)
        invertYaw = [(NSButton*)sender state];
}
-(IBAction)pitchSliderChange:(id)sender{
    if([_pitchSlider integerValue] > MAX_AXIS_RANGE)
        [_pitchSlider setIntValue:MAX_AXIS_RANGE];
    else if([_pitchSlider integerValue] < MIN_AXIS_RANGE)
        [_pitchSlider setIntValue:MIN_AXIS_RANGE];
    pitchRange = (int)[(NSSlider*)sender integerValue];
    [self preferencesDidUpdate];
}
-(IBAction)rollSliderChange:(id)sender{
    if([_rollSlider integerValue] > MAX_AXIS_RANGE)
        [_rollSlider setIntValue:MAX_AXIS_RANGE];
    else if([_rollSlider integerValue] < MIN_AXIS_RANGE)
        [_rollSlider setIntValue:MIN_AXIS_RANGE];
    rollRange = (int)[(NSSlider*)sender integerValue];
    [self preferencesDidUpdate];
}
-(IBAction)yawSliderChange:(id)sender{
    if([_yawSlider integerValue] > MAX_AXIS_RANGE)
        [_yawSlider setIntValue:MAX_AXIS_RANGE];
    else if([_yawSlider integerValue] < MIN_AXIS_RANGE)
        [_yawSlider setIntValue:MIN_AXIS_RANGE];
    yawRange = (int)[(NSSlider*)sender integerValue];
    [self preferencesDidUpdate];
}
-(void) preferencesDidUpdate{
    [_pitchRangeField setStringValue:[NSString stringWithFormat:@"%d°",pitchRange]];
    [_rollRangeField setStringValue:[NSString stringWithFormat:@"%d°",rollRange]];
    [_yawRangeField setStringValue:[NSString stringWithFormat:@"%d°",yawRange]];
}
-(void) connectionsDidUpdate{
    [statusView updateStateCapable:_isBLECapable Enabled:_isBLEEnabled Connected:_connectionState];
    NSString *deviceName = [_peripheral name];
    if(!deviceName) deviceName = @"";
    [statusView setDeviceID:deviceName];
}
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([_centralManager state]){
        case CBCentralManagerStateUnsupported:
            state = @"This must be frustrating, I'm sorry, your computer doesn't have Bluetooth Low Energy";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app needs permission to use Bluetooth Low Energy";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Turn on Bluetooth Low Energy and try again";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            state = @"Bluetooth status unknown";
//            return FALSE;
    }
    
    NSLog(@"Central manager state: %@", state);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
//TODO: Alert not presenting
//    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    _centralManager = nil;
    return FALSE;
}

#pragma mark- VIRTUAL HID

-(void) createVirtualJoystick{
    joystickDescription = [[VHIDDevice alloc] initWithType:VHIDDeviceTypeJoystick pointerCount:4 buttonCount:1 isRelative:NO];
    [joystickDescription setDelegate:self];
    virtualJoystick = [[WJoyDevice alloc] initWithHIDDescriptor:[joystickDescription descriptor] productString:@"BLE Joystick"];
//    virtualJoystick = [[WJoyDevice alloc] initWithHIDDescriptor:[joystickDescription descriptor] properties:@{WJoyDeviceProductStringKey : @"iOSVirtualJoystick", WJoyDeviceSerialNumberStringKey : @"556378"}];
}
-(void) destroyVirtualJoystick{
    joystickDescription.delegate = nil;
    joystickDescription = nil;
    virtualJoystick = nil;
}
-(void) VHIDDevice:(VHIDDevice *)device stateChanged:(NSData *)state{
    if(virtualJoystick)
        [virtualJoystick updateHIDState:state];
}

#pragma mark- BLUETOOTH MASTER

-(void) setIsBLECapable:(BOOL)isBLECapable{
    _isBLECapable = isBLECapable;
//    if(isBLECapable) _isBLEEnabled = true;
//    if(!isBLECapable) _isBLEEnabled = false;
    [self connectionsDidUpdate];
}

#pragma mark- BLUETOOTH DEVICE CONNECTION

-(void)setIsBLEEnabled:(BOOL)isBLEEnabled{
    _isBLEEnabled = isBLEEnabled;
    [self connectionsDidUpdate];
    if(!_isBLEEnabled){
        [self setConnectionState:BLEConnectionStateDisconnected];
    }
}
-(void)bootScanIfPossible{
    if(_connectionState == BLEConnectionStateDisconnected)
        [self setConnectionState:BLEConnectionStateScanning];
}
-(void) scanClockLoopFunction{
    if(scanClock >= countingCharacters.length-1){
        [self setConnectionState:BLEConnectionStateDisconnected];
        return;
    }
    scanClock++;
    NSLog(@"scanning (%lusec)",(unsigned long)scanClock);
    [_scanOrEjectMenuItem setTitle:[NSString stringWithFormat:@"%@ Scanning",[countingCharacters substringWithRange:NSMakeRange(scanClock, 1)]]];
}
-(void) startScan{
    NSLog(@"startScan");
    scanClock = 0;
    scanClockLoop = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(scanClockLoopFunction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:scanClockLoop forMode:NSRunLoopCommonModes];
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [_centralManager scanForPeripheralsWithServices:services options:nil];
}
-(void) setConnectionState:(BLEConnectionState)connectionState{
    _connectionState = connectionState;
    if(connectionState == BLEConnectionStateDisconnected){
        if(scanClockLoop){
            [scanClockLoop invalidate];
            scanClockLoop = nil;
        }
        if(_centralManager && _peripheral){
            [_centralManager cancelPeripheralConnection:_peripheral];
            _peripheral = nil;
        }
        [self destroyVirtualJoystick];
        [_scanOrEjectMenuItem setImage:[NSImage imageNamed:NSImageNameRefreshTemplate]];
        [_scanOrEjectMenuItem setTitle:@"Scan"];
        [_scanOrEjectMenuItem setEnabled:YES];
    }
    else if(connectionState == BLEConnectionStateScanning){
        [_scanOrEjectMenuItem setEnabled:NO];
        [_scanOrEjectMenuItem setImage:nil];
        [_scanOrEjectMenuItem setTitle:[NSString stringWithFormat:@"%@ Scanning",[countingCharacters substringWithRange:NSMakeRange(0, 1)]]];
        if(scanClockLoop == nil){
            [self startScan];
        }
    }
    else if(connectionState == BLEConnectionStateConnected){
        if(scanClockLoop){
            [scanClockLoop invalidate];
            scanClockLoop = nil;
        }
        [self createVirtualJoystick];
        [_scanOrEjectMenuItem setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
        [_scanOrEjectMenuItem setTitle:@"Disconnect"];
        [_scanOrEjectMenuItem setEnabled:YES];
    }
    [self connectionsDidUpdate];
}
-(BOOL) addPeripheralInRangeIfUnique:(CBPeripheral*)peripheral RSSI:(NSNumber*)RSSI{
    // returns YES if addition was made
    BOOL alreadyFound = NO;
    for(NSDictionary *p in peripheralsInRange){
        if([[peripheral name] isEqualToString:[p objectForKey:@"name"]])
            alreadyFound = YES;
    }
    if(!alreadyFound){
        [peripheralsInRange addObject:@{@"name" : [peripheral name],
                                        @"RSSI" : RSSI,
                                        @"state" : [NSNumber numberWithInt:[peripheral state]]} ];
    }
    return !alreadyFound;
}

#pragma mark - DATA & MATH

-(void) cropPitch:(float*)pitch Roll:(float*)roll Yaw:(float*)yaw{
    *pitch /= (pitchRange/180.0);
    if(*pitch > 1.0) *pitch = 1.0;
    *roll /= (rollRange/180.0);
    if(*roll > 1.0) *roll = 1.0;
    *yaw /= (yawRange/180.0);
    if(*yaw > 1.0) *yaw = 1.0;
}

-(void) quaternion:(float*)q ToPitch:(float*)pitch Roll:(float*)roll Yaw:(float*)yaw{
    GLKQuaternion quat = GLKQuaternionMake(q[0], q[1], q[2], q[3]);
    GLKMatrix4 matrix = GLKMatrix4MakeWithQuaternion(quat);
    int pD = invertPitch ? -1 : 1;
    int rD = invertRoll ? -1 : 1;
    int yD = invertYaw ? -1 : 1;
    *yaw =   yD * atan2f(matrix.m10, sqrtf(powf(matrix.m11,2) + powf(matrix.m12,2) ) );
    *roll = rD * -atan2f(matrix.m12, sqrtf(powf(matrix.m10,2) + powf(matrix.m11,2) ) );
    *pitch = pD * atan2f(matrix.m02, sqrtf(powf(matrix.m12,2) + powf(matrix.m22,2) ) );
    
//    NSLog(@"1:(%f)  2:(%f)",matrix.m02, sqrtf(powf(matrix.m12,2) + powf(matrix.m22,2) ));
//    NSLog(@"\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n",
//          matrix.m00, matrix.m01, matrix.m02,
//          matrix.m10, matrix.m11, matrix.m12,
//          matrix.m20, matrix.m21, matrix.m22);
}
-(void) unpackData:(NSData*)receivedData IntoQuaternionX:(float*)x Y:(float*)y Z:(float*)z W:(float*)w {
    char *data = (char*)[receivedData bytes];
    *x = data[0] / 128.0f;
    *y = data[1] / 128.0f;
    *z = data[2] / 128.0f;
    *w = data[3] / 128.0f;
}

#pragma mark- DELEGATES - BLE CENTRAL

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    NSLog(@"central delegate: didConnectPeripheral: %@", peripheral.name);
    
    [self setConnectionState:BLEConnectionStateConnected];
    
    // Let's qeury the service
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:SERVICE_UUID]];
    [peripheral discoverServices:services];
    NSLog(@"SERVICES: %@",services);
}
-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"central delegate: didDiscoverPeripheral");

    if([self addPeripheralInRangeIfUnique:peripheral RSSI:RSSI])
        [statusView setDevicesInRange:peripheralsInRange];
    
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
    NSLog(@"%@",str);
//    if([SERVICE_PREFIX isEqual:[str substringToIndex:32]]){
    if([str isEqual:SERVICE_UUID]){
        NSLog(@"Peripheral is in our service!");

        NSLog(@"Peripheral.name: %@",peripheral.name);
        NSLog(@"Peripheral.services: %@",peripheral.services);
        NSLog(@"Peripheral.state: %ld",peripheral.state);
        NSLog(@"advertisementData: %@",advertisementData);
        NSLog(@"RSSI: %@",RSSI);
        
        [_centralManager stopScan];
        
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
    if(central.state == CBCentralManagerStatePoweredOn){
        NSLog(@"central delegate: central powered on");
        
        [self setIsBLECapable:[self isLECapableHardware]]; // will dealloc _centralManager if unsuccessful
        // re order this better
        if(_centralManager && _isBLECapable)
            [self bootScanIfPossible];
    }
    if(central.state == CBCentralManagerStatePoweredOff){
        NSLog(@"central delegate: central powered off");
        [self setIsBLEEnabled:NO];
    }
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

    static const float halfpi = M_PI*.5;
    
    if ([characteristic.value length] == 4) {  //([characteristic.value bytes]){
        float q[4];
        [self unpackData:[characteristic value] IntoQuaternionX:&q[0] Y:&q[1] Z:&q[2] W:&q[3]];

        float pitch, roll, yaw;
        [self quaternion:q ToPitch:&pitch Roll:&roll Yaw:&yaw];

        pitch /= halfpi;
        roll /= halfpi;
        yaw /= halfpi;
        
        [self cropPitch:&pitch Roll:&roll Yaw:&yaw];

        [joystickDescription setPointer:0 position:CGPointMake(pitch, roll)];
        [joystickDescription setPointer:1 position:CGPointMake(yaw, 0)];
//        [joystickDescription setPointer:2 position:CGPointMake(0, 0)];
        
        if(_orientationWindowVisible){
            [orientationView setOrientation:q];
            [orientationView setNeedsDisplay:true];
        }
    }
    else if ([characteristic.value length] == 1) {
        char *touched = (char*)[[characteristic value] bytes];
        BOOL t = *touched;
        [orientationView setScreenTouched:t];
    }
    else if ([characteristic.value length] == 2){
        char *data = (char*)[[characteristic value] bytes];
        if (*data == 0x3b){ // exit code
            [self setConnectionState:BLEConnectionStateDisconnected];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"delegate: didWriteValueForCharacteristic");
}


@end
