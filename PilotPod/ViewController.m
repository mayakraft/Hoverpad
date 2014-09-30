//
//  ViewController.m
//  PilotPod
//
//  Created by Robby Kraft on 3/8/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "ViewController.h"

#define SERVICE_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F30"

#define READ_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F40"
#define WRITE_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F41"
#define NOTIFY_CHAR_UUID @"27E6BBA2-008E-4FFC-BC88-E8D3088D5F42"

#define START @"START"
#define INIT @"INIT"
#define STOP @"STOP"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
//    self.uuid = [[UITextField alloc] initWithFrame:CGRectMake(50, 50, [[UIScreen mainScreen] bounds].size.width-100, 75)];
//    [self.view addSubview:self.uuid];
//    self.uuid.text = SERVICE_UUID;
    
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
    
    if (!motionManager) {
        motionManager = [[CMMotionManager alloc] init];
    }
    if (motionManager){
        if(motionManager.isDeviceMotionAvailable){
            motionManager.deviceMotionUpdateInterval = 1.0/10.0;///45.0;
            [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                               withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
                
                [myPeripheralManager updateValue:[self encodeQuaternion:deviceMotion.attitude.quaternion]
                               forCharacteristic:myNotifyChar
                            onSubscribedCentrals:nil];

//                normalized = attitude * lastAttitude;  // results in the identity matrix plus perturbations between polling cycles
//                lastAttitude = attitude;   // store last polling cycle to compare next time around
//                lastAttitude.transpose();  //getInverse(attitude);  // transpose is the same as inverse for orthogonal matrices. and much easier
//             log2Matrices3x3(normalized, attitude);
            }];
        }
    }
}

-(void) updateTouchIfChanged:(BOOL)isTracking{
    if (screenTouched != isTracking) {
        screenTouched = isTracking;
        [self updateState];
    }
}

-(void) updateState{
    unsigned char d = (screenTouched ? 1 : 0);
    [myPeripheralManager updateValue:[NSData dataWithBytes:&d length:1]
                   forCharacteristic:myNotifyChar
                onSubscribedCentrals:nil];

}

-(void) screenTouch:(UIButton*)sender{
    [self updateTouchIfChanged:sender.isTracking];
}

-(NSData*) encodeQuaternion:(CMQuaternion)q{
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)getServiceUuidAsString
{
    return SERVICE_UUID;
}

- (IBAction)buttonTapped:(id)sender
{
    if (sender != self.theButton) {
        NSLog(@"Something is wrong!");
        return;
    }
    
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

- (void)initPeripheral
{
    myReadChar = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:READ_CHAR_UUID]
                                                    properties:CBCharacteristicPropertyRead
                                                         value:nil
                                                   permissions:CBAttributePermissionsReadable
                  ];
    myWriteChar = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:WRITE_CHAR_UUID]
                                                     properties:CBCharacteristicPropertyWrite
                                                          value:nil
                                                    permissions:CBAttributePermissionsWriteable
                   ];
    
    myNotifyChar = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:NOTIFY_CHAR_UUID]
                                                      properties:CBCharacteristicPropertyNotify
                                                           value:nil
                                                     permissions:0
                    ];
    
    myPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}


- (NSString*)getName
{
    return [[self getServiceUuidAsString] substringFromIndex:[[self getServiceUuidAsString] length]-4];
}

- (void)startAdvertisements
{
    NSLog(@"Starting advertisements...");
    
    NSMutableDictionary *advertisingDict = [NSMutableDictionary dictionary];
    [advertisingDict setObject:[self getName] forKey:CBAdvertisementDataLocalNameKey];
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:[self getServiceUuidAsString]]];
    [advertisingDict setObject:services forKey:CBAdvertisementDataServiceUUIDsKey];
    [myPeripheralManager startAdvertising:advertisingDict];
}

- (void)stopAdvertisements
{
    NSLog(@"Stopping advertisements...");
    
    [myPeripheralManager stopAdvertising];
    
    NSLog(@"Advertisements stopped!");
    [self.theButton setTitle:INIT forState:UIControlStateNormal];
    myPeripheralManager = nil;
    self.theButton.enabled = YES;
}


- (void)addService{
    NSLog(@"addService");
    CBUUID *serviceUUID = [CBUUID UUIDWithString:[self getServiceUuidAsString]];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    NSMutableArray *characteristics = [NSMutableArray array];
    
    [characteristics addObject:myReadChar];
    [characteristics addObject:myWriteChar];
    [characteristics addObject:myNotifyChar];
    
    service.characteristics = characteristics;
    
    [myPeripheralManager addService:service];
}



#pragma mark Peripheral Manager delegates

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (myPeripheralManager.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"Peripheral powered on, we are in business!");
            [self addService];
            [self.theButton setTitle:START forState:UIControlStateNormal];
            self.theButton.enabled = YES;
            break;
        default:
            NSLog(@"Peripheral state changed to %d", myPeripheralManager.state);
            break;
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"Advertisements started!");
    [self.theButton setTitle:STOP forState:UIControlStateNormal];
    self.theButton.enabled = YES;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"Received write request!");
    for(CBATTRequest* request in requests) {
//        if ([request.value bytes]) {
//            self.receivedText.text = [[NSString alloc ] initWithBytes:[request.value bytes] length:request.value.length encoding:NSASCIIStringEncoding];
//        } else {
//            self.receivedText.text = @"";
//        }
        [myPeripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"Received read request!");
    NSString *valueToSend;
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm:ss"];
    valueToSend = [dateFormatter stringFromDate: currentTime];
    
    request.value = [valueToSend dataUsingEncoding:NSASCIIStringEncoding];
    
    [myPeripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed!");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed!");
}


@end
