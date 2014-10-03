//
//  ViewController.m
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "ViewController.h"

#define SERVICE_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE30"

#define READ_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE31"
#define WRITE_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE32"
#define NOTIFY_CHAR_UUID @"2166E780-4A62-11E4-817C-0002A5D5DE33"

#define START @"START"
#define INIT @"BOOT"
#define STOP @"STOP"

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    UIButton *screenButton = [[UIButton alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [screenButton setBackgroundColor:[UIColor clearColor]];
    [screenButton setBackgroundImage:[UIImage imageNamed:@"white.png"] forState:UIControlStateHighlighted];
    [screenButton addTarget:self action:@selector(screenTouch:) forControlEvents:UIControlEventAllTouchEvents];
    [self.view addSubview:screenButton];

    self.theButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.theButton setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width*.5-50, [[UIScreen mainScreen] bounds].size.height*.5-25, 100, 50)];
    [self.theButton setTitle:INIT forState:UIControlStateNormal];
    [self.theButton.titleLabel setFont:[UIFont systemFontOfSize:[[UIScreen mainScreen] bounds].size.width*.1]];
    [self.theButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.theButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.theButton];
    
    identity = GLKQuaternionIdentity;
    
    if (!motionManager) {
        motionManager = [[CMMotionManager alloc] init];
    }
    if (motionManager && motionManager.isDeviceMotionAvailable){
        motionManager.deviceMotionUpdateInterval = 1.0/30.0;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error){
        
            CMQuaternion q = deviceMotion.attitude.quaternion;
            lq.x = q.x;   lq.y = q.y;   lq.z = q.z;   lq.w = q.w;
            if(screenTouched){
                identity = GLKQuaternionInvert(lq);//lq;
            }
            NSData *newOrientation = [self encodeQuaternion:GLKQuaternionMultiply(identity, lq)];
            if(![_orientation isEqualToData:newOrientation]){
                [self setOrientation:newOrientation];
            }
        }];
    }
}

-(void) setOrientation:(NSData *)orientation{
    _orientation = orientation;
    [peripheralManager updateValue:orientation forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) updateTouchIfChanged:(BOOL)isTracking{
    if (screenTouched != isTracking) {
        // touch changed
        screenTouched = isTracking;
        [self updateState];
    }
}

-(void) sendDisconnect{
//    unsigned char exit[2]; // Hex 3b;
    unsigned char exit[2] = {0x3b};
    [peripheralManager updateValue:[NSData dataWithBytes:&exit length:2] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) updateState{
    unsigned char d = (screenTouched ? 1 : 0);
    [peripheralManager updateValue:[NSData dataWithBytes:&d length:1] forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
}

-(void) screenTouch:(UIButton*)sender{
    [self updateTouchIfChanged:sender.isTracking];
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

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonTapped:(id)sender{

    self.theButton.enabled = NO;
    
    if ([self.theButton.titleLabel.text isEqualToString:INIT]) {
        [self initPeripheral];
    }
    
    if ([self.theButton.titleLabel.text isEqualToString:START]) {
        [self startAdvertisements];
    }
    
    if ([self.theButton.titleLabel.text isEqualToString:STOP]) {
        [self stopAdvertisements];
    }
}

/////////////////////////////////////////////////////

- (void)initPeripheral{
    NSLog(@"initPeripheral");

    readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:READ_CHAR_UUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:WRITE_CHAR_UUID] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:0];

    peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (NSString*)getName{
    return [SERVICE_UUID substringFromIndex:[SERVICE_UUID length]-4];
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
//    peripheralManager = nil;
    

    
    NSLog(@"Advertisements stopped!");
    [self.theButton setTitle:START forState:UIControlStateNormal];
    self.theButton.enabled = YES;
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

#pragma mark Peripheral Manager delegates

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    if([peripheralManager state] == CBPeripheralManagerStatePoweredOn){
        NSLog(@"delegate: Peripheral powered on, we are in business!");
        
        [peripheralManager addService:[self constructService:SERVICE_UUID]];
        
        [self.theButton setTitle:START forState:UIControlStateNormal];
        self.theButton.enabled = YES;
    }
    else{
        NSLog(@"delegate: Peripheral state changed to %d", (int)[peripheralManager state]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"delegate: Advertisements started!");
    [self.theButton setTitle:STOP forState:UIControlStateNormal];
    self.theButton.enabled = YES;
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


@end
