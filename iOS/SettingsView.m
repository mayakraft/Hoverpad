//
//  SettingsView.m
//  Autonaut
//
//  Created by Robby on 6/4/13.
//  Copyright (c) 2013 robbykraft. All rights reserved.
//

#import "SettingsView.h"
#import "Cell.h"
#import "DetailCell.h"
#import "ConnectionCell.h"
#import "WelcomeCell.h"
#import "InstructionsCell.h"

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define NUM_CELLS 5
#define CYCLE_TIME .1f
#define CONNECTION_ON @"\n\n⠐⠀COMMUNICATION⠀⠂"
#define CONNECTION_OFF @"\n\n⠀⠀COMMUNICATION⠀⠀"

@interface SettingsView (){
    NSTimer *colorTimer;
    float cycle;  // color cycle
    NSTimer *lightTimer;
}

@end

@implementation SettingsView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if(self) {
        [self initialize];
    }
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self initialize];
    }
    return self;
}
-(id)  init{
    self = [super init];
    if(self){
        [self initialize];
    }
    return self;
}
-(void) initialize{
    _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
    colorTimer = [NSTimer scheduledTimerWithTimeInterval:CYCLE_TIME target:self selector:@selector(cycleColor) userInfo:nil repeats:YES];
    [self setDataSource:self];
    [self setClipsToBounds:NO];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setBackgroundView:nil];
    [self setSeparatorInset:UIEdgeInsetsZero];
    [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setSectionHeaderHeight:1.0];
    [self setSectionFooterHeight:1.0];
}
-(void) fakeDealloc{
    if(colorTimer){
        [colorTimer invalidate];
        colorTimer = nil;
    }
//    free(_cellExpanded);
}
-(void) dealloc{
    if(colorTimer){
        [colorTimer invalidate];
        colorTimer = nil;
    }
    free(_cellExpanded);
}

// fake flip orientation
- (void)setFrame:(CGRect)frame {
    float temp = frame.size.height;
    frame.size.height = frame.size.width;
    frame.size.width = temp;
    [super setFrame:frame];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return NUM_CELLS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(_cellExpanded[section])
        return 2;
    return 1;
}
- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section{
    return 1.0f;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}

-(UIColor *)getColorForSection:(int)section{
    float hue = ((float)(4-section)/NUM_CELLS) + cycle;
    if(hue > 1.0) hue -= 1.0;
    if(hue < 0.0) hue += 1.0;
    return [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
}

-(void) setConnectionState:(NSInteger)connectionState{
    _connectionState = connectionState;
    [self updateConnectionTitleCell:nil];
    [self updateConnectionDetailCell:nil];
    [self flashCommunicationLight];
}

-(void) flashCommunicationLight{
    if(!lightTimer){
        UITableViewCell * cell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        if(cell)
            [[cell textLabel] setText:CONNECTION_ON];
        [self performSelector:@selector(offLightCommunication) withObject:nil afterDelay:1/30.0];
    }
}

-(void) offLightCommunication{
    if(self){
        UITableViewCell * cell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        if(cell)
            [[cell textLabel] setText:CONNECTION_OFF];
    }
}

-(void) updateConnectionTitleCell:(UITableViewCell*) cellIn{
    UITableViewCell *cell;
    if(cellIn) cell = cellIn;
    else cell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

    if(cell){
        if(_connectionState == 3){
            [[cell detailTextLabel] setText:@"✔︎"];
            [[cell detailTextLabel] setTextColor:[UIColor greenColor]];
        }
        else if (_connectionState == 0){
            [[cell detailTextLabel] setText:@"✘"];
            [[cell detailTextLabel] setTextColor:[UIColor redColor]];
        }
        else{
            [[cell detailTextLabel] setText:@"..."];
            [[cell detailTextLabel] setTextColor:[UIColor yellowColor]];
        }
    }
}

-(void) updateConnectionDetailCell:(UITableViewCell*) cellIn{
    UITableViewCell *cell;
    if(cellIn) cell = cellIn;
    else cell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    
    if(cell){
        // BLUETOOTH LOW ENERGY NOT AVAILABLE
        if(_hardwareState == 2){//|| _hardwareState == 1 || _hardwareState == 3){
            [[cell textLabel] setText:@"\n\nDEVICE CAN'T FUNCTION"];
            [[cell detailTextLabel] setText:@"NO BLUETOOTH 4.0"];
            [[cell detailTextLabel] setTextColor:[UIColor redColor]];
            return;
        }
        if(_connectionState == 3){
            [[cell textLabel] setText:CONNECTION_OFF];
            [[cell detailTextLabel] setText:@"CONNECTED"];
            [[cell detailTextLabel] setTextColor:[UIColor greenColor]];
        }
        else if (_connectionState == 2){
            [[cell textLabel] setText:@"\n\nMAKE SURE DESKTOP IS ALSO LOOKING"];
            [[cell detailTextLabel] setText:@"SCANNING"];
            [[cell detailTextLabel] setTextColor:[UIColor yellowColor]];
        }
        else if (_connectionState == 0){
            [[cell textLabel] setText:@"\n\nTAP HERE TO BEGIN SEARCHING"];
            // flash communication lights still happens, and erases "tap here to begin searching"
            [[cell detailTextLabel] setText:@"DISCONNECTED"];
            [[cell detailTextLabel] setTextColor:[UIColor redColor]];
        }
        else if (_connectionState == 4){
            [[cell textLabel] setText:@"\n\nCONNECTION IS EXPIRING"];
            [[cell detailTextLabel] setText:@"DISCONNECTING"];
            [[cell detailTextLabel] setTextColor:[UIColor yellowColor]];
        }
        else if (_connectionState == 1){
            [[cell textLabel] setText:@"\n\nBLUETOOTH IS INITIALIZING"];
            [[cell detailTextLabel] setText:@"BOOTING"];
            [[cell detailTextLabel] setTextColor:[UIColor yellowColor]];
        }
    }
}

-(void) cycleColor{
    for(int i = 0; i < NUM_CELLS; i++){
        float hue = ((float)(4-i)/NUM_CELLS) + cycle;
        if(hue > 1.0) hue -= 1.0;
        if(hue < 0.0) hue += 1.0;
        UIColor *rainbow = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
        UITableViewCell *cell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
        if(cell){
            [[cell textLabel] setTextColor:rainbow];
            [[cell layer] setBorderColor:rainbow.CGColor];
        }
        if(_cellExpanded[i]){
            UITableViewCell *cellD = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:i]];
            if(cellD){
                [[cellD layer] setBorderColor:rainbow.CGColor];
            }
        }
    }
    cycle += .005;
    if(cycle > 1.0) cycle -= 1.0;
}

//TODO: PADDING NOT DYNAMIC
#define PADDING 20


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    //Cell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UIColor *rainbow = [self getColorForSection:indexPath.section];

    float smFont = 20.0 + 20 * IS_IPAD();
    
// ALL ROW 1 CELLS (DETAIL CELLS)
    if(indexPath.row == 1){
        if(indexPath.section == 3){
            InstructionsCell *cell = [[InstructionsCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            [[cell layer] setBorderColor:rainbow.CGColor];
            return cell;
        }
        if(indexPath.section == 0){
            WelcomeCell *cell = [[WelcomeCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            [[cell layer] setBorderColor:rainbow.CGColor];
            return cell;
        }
        if(indexPath.section == 1){
            ConnectionCell *cell = [[ConnectionCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            [[cell layer] setBorderColor:rainbow.CGColor];
//            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:smFont]];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
            [self updateConnectionDetailCell:cell];
            return cell;
        }
        DetailCell *cell = [[DetailCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        [[cell layer] setBorderColor:rainbow.CGColor];
        if(indexPath.section == 2){
            [[cell textLabel] setText:@"MAKE SURE YOU HAVE THE DESKTOP APP\n\nCONNECTION PROCESS:\nTAP THE PENTAGON TO BEING SEARCHING\n ‣ BEGIN SCAN ON BOTH iOS & DESKTOP APPS\n ‣ CONNECTION REQUIRES 3-7 SECONDS\n\nTROUBLESHOOTING:\nIF CONNECTION BREAKS WITHOUT PROPER EXIT\n ‣ FORCE QUIT THE APP. IF STILL UNSUCCESSFUL, GO TO PHONE'S SETTINGS, TURN BLUETOOTH OFF & ON, WAITING A FEW SECONDS"];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:smFont]];
        }
        return cell;
    }
    
    Cell *cell = [[Cell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    [[cell layer] setBorderColor:rainbow.CGColor];
    cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y-indexPath.row*10, cell.frame.size.width, cell.frame.size.height);

    [[cell textLabel] setTextColor:rainbow];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [[cell detailTextLabel] setText:@""];

    if(indexPath.section == 0){
        [[cell textLabel] setText:@"▲ HOVERPAD ▲"];
    }
    else if (indexPath.section == 1){
        [[cell textLabel] setText:@"CONNECTION STATUS"];
        [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
        [self updateConnectionTitleCell:cell];
    }
    else if (indexPath.section == 2){
        [[cell textLabel] setText:@"SETUP HELP"];
    }
    else if (indexPath.section == 3){
        [[cell textLabel] setText:@"BEST PRACTICES"];
    }
    else if (indexPath.section == 4){
        [[cell textLabel] setText:@"OKAY"];
    }
    return cell;
}

@end
