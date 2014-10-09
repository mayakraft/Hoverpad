//
//  ViewController.m
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "ViewController.h"

#define SERVICE_UUID     @"2166E780-4A62-11E4-817C-0002A5D5DE30"
#define READ_CHAR_UUID   @"2166E780-4A62-11E4-817C-0002A5D5DE31"
#define WRITE_CHAR_UUID  @"2166E780-4A62-11E4-817C-0002A5D5DE32"
#define NOTIFY_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE33"

#define START @"START"
#define STOP @"STOP"

@implementation ViewController

-(id) init{
    self = [super init];
    if(self) [self setupContext];
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self) [self setupContext];
    return self;
}
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) [self setupContext];
    return self;
}
-(void) setupContext{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:context];
    screenView = [[ScreenView alloc] initWithFrame:[[UIScreen mainScreen] bounds] context:context];
    [self setView:screenView];
    
    _UUID = [self random16bit:4];
    identity = GLKQuaternionIdentity;
    if (!motionManager) {
        motionManager = [[CMMotionManager alloc] init];
    }
    if (motionManager && motionManager.isDeviceMotionAvailable){
        motionManager.deviceMotionUpdateInterval = 1.0/30.0;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error){
            
            CMQuaternion q = deviceMotion.attitude.quaternion;
            lq.x = q.x;   lq.y = q.y;   lq.z = q.z;   lq.w = q.w;
            if(_screenTouched){
                identity = GLKQuaternionInvert(lq);
            }
            NSData *newOrientation = [self encodeQuaternion:GLKQuaternionMultiply(identity, lq)];
            if(![_orientation isEqualToData:newOrientation]){
                [self setOrientation:newOrientation];
            }
        }];
    }
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [screenView draw];
}

#pragma mark- TOUCHES

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(CGRectRadianContainsPoint(CGPointMake([[UIScreen mainScreen] bounds].size.width*.5, [[UIScreen mainScreen] bounds].size.height*.5), 30, [[touches anyObject] locationInView:screenView])){
        
        // touches began inside button area
        if(!_buttonTouched){
            [self setButtonTouched:YES];
            [self buttonTapped];
        }
    }
    else if(!_screenTouched){
        [self setScreenTouched:YES];
    }
}
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{ }
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(_screenTouched){
        [self setScreenTouched:NO];
    }
    if(_buttonTouched){
        [self setButtonTouched:NO];
    }
}
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"TOUCHES CANCELLED");
    if(_screenTouched){
        [self setScreenTouched:NO];
    }
}
-(void) setScreenTouched:(BOOL)screenTouched{
    _screenTouched = screenTouched;
    [screenView setIsScreenTouched:screenTouched];
    [self updateState];
}
-(void) setButtonTouched:(BOOL)buttonTouched{
    _buttonTouched = buttonTouched;
    [screenView setIsButtonTouched:buttonTouched];
}
-(void) setState:(PeripheralConnectionState)state{
    _state = state;
    [screenView setState:state];
    NSLog(@"STATE CHANGE: %d",state);
//    if(state == PeripheralConnectionStateDisconnected);
//    if(state == PeripheralConnectionStateBooting);
//    if(state == PeripheralConnectionStateScanning);
//    if(state == PeripheralConnectionStateScanning);
//    if(state == PeripheralConnectionStateDisconnecting);
}
-(void) buttonTapped{
    
    if(_state == PeripheralConnectionStateDisconnected){
        [self setState:PeripheralConnectionStateBooting];
        [self initPeripheral];
        connectionTime = [NSDate date];
        [screenView setConnectionTime:[NSDate date]];
    }
    else if(_state == PeripheralConnectionStateConnected){
        [self setState:PeripheralConnectionStateDisconnecting];
        [self stopAdvertisements];
    }
}

#pragma mark- BLUETOOTH LOW ENERGY

-(void) setOrientation:(NSData *)orientation{
    _orientation = orientation;
    [peripheralManager updateValue:orientation forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) sendDisconnect{
    unsigned char exit[2] = {0x3b};
    [peripheralManager updateValue:[NSData dataWithBytes:&exit length:2] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) updateState{
    unsigned char d = (_screenTouched ? 1 : 0);
    [peripheralManager updateValue:[NSData dataWithBytes:&d length:1] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

- (void)initPeripheral{
    NSLog(@"initPeripheral");

    readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:READ_CHAR_UUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:WRITE_CHAR_UUID] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:0];

    peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (NSString*)getName{
    return @"Hoverpad";//[NSString stringWithFormat:@"%@",_UUID];
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
    [self setState:PeripheralConnectionStateConnected];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"delegate: Received write request!");
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
    NSLog(@"delegate: Received read request!");
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
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"delegate: Central unsubscribed!");
}

#pragma mark - MATH & DATA

-(NSString*)random16bit:(NSUInteger)numberOfDigits{
    NSString *string = @"";
    for(int i = 0; i < numberOfDigits; i++){
        int number = arc4random()%16;
        if(number > 9){
            char letter = 'A' + number - 10;
            string = [string stringByAppendingString:[NSString stringWithFormat:@"%c",letter]];
        }
        else
            string = [string stringByAppendingString:[NSString stringWithFormat:@"%d",number]];
    }
    return string;
}

-(NSData*) encodeQuaternion:(GLKQuaternion)q{
    // encodes (x,y,z)w quaternion floats into signed char
    // -1.0 to 1.0 into -127 to 127
    char bytes[4];
    short temp;
    temp = q.x * 128.0f;
    bytes[0] = (char)temp;
    bytes[1] = (char)(q.y * 128.0f);
    bytes[2] = (char)(q.z * 128.0f);
    bytes[3] = (char)(q.w * 128.0f);
    return [NSData dataWithBytes:bytes length:4];
}


@end
