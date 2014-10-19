//
//  SettingsView.m
//  Autonaut
//
//  Created by Robby on 6/4/13.
//  Copyright (c) 2013 robbykraft. All rights reserved.
//

#import "SettingsView.h"
#import "Cell.h"

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define NUM_CELLS 5
#define  CYCLE_TIME .1f

@interface SettingsView (){
    NSTimer *colorTimer;
    float cycle;  // color cycle
}

@end

@implementation SettingsView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if(self) {
        _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
        colorTimer = [NSTimer scheduledTimerWithTimeInterval:CYCLE_TIME target:self selector:@selector(cycleColor) userInfo:nil repeats:YES];
    }
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self) {
        _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
        colorTimer = [NSTimer scheduledTimerWithTimeInterval:CYCLE_TIME target:self selector:@selector(cycleColor) userInfo:nil repeats:YES];
    }
    return self;
}
-(id)  init{
    self = [super init];
    if(self){
        _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
        colorTimer = [NSTimer scheduledTimerWithTimeInterval:CYCLE_TIME target:self selector:@selector(cycleColor) userInfo:nil repeats:YES];
    }
    return self;
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
        if(_connectionState == 3){
            [[cell textLabel] setText:@"\n\nCOMMUNICATION OPEN"];
            [[cell detailTextLabel] setText:@"CONNECTED"];
            [[cell detailTextLabel] setTextColor:[UIColor greenColor]];
        }
        else if (_connectionState == 2){
            [[cell textLabel] setText:@"\n\nMAKE SURE DESKTOP IS SEARCHING TOO"];
            [[cell detailTextLabel] setText:@"SCANNING"];
            [[cell detailTextLabel] setTextColor:[UIColor yellowColor]];
        }
        else if (_connectionState == 0){
            [[cell textLabel] setText:@"\n\nTAP HERE TO BEGIN SEARCHING\n(OR TAP PENTAGON ON MAIN WINDOW)"];
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
//                [[cellD textLabel] setTextColor:rainbow];
                [[cellD layer] setBorderColor:rainbow.CGColor];
            }
        }
    }
    cycle += .005;
    if(cycle > 1.0) cycle -= 1.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    //Cell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Cell *cell = [[Cell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

//    UIColor *rainbow = [UIColor colorWithHue:((float)(4-indexPath.section)/NUM_CELLS) saturation:1.0 brightness:1.0 alpha:1.0];
    UIColor *rainbow = [self getColorForSection:indexPath.section];
    [[cell layer] setBorderColor:rainbow.CGColor];
    
    cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y-indexPath.row*10, cell.frame.size.width, cell.frame.size.height);
    
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            [[cell textLabel] setTextColor:rainbow];
            [[cell textLabel] setText:@"▲ HOVERPAD ▲"];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
            [[cell detailTextLabel] setText:@""];
        }
        else{
            [cell setFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, 180)];
            [[cell textLabel] setText:@"TURNS YOUR PHONE INTO A 3 AXIS\n(PITCH, ROLL, YAW) ANALOG JOYSTICK"];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
            [[cell detailTextLabel] setText:@""];
        }
    }
    else if (indexPath.section == 1){
        if(indexPath.row == 0){
            [[cell textLabel] setText:@"CONNECTION STATUS"];
            [[cell textLabel] setTextColor:rainbow];
            [self updateConnectionTitleCell:cell];
        }
        else{
            [cell setFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, 180)];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
            [[cell detailTextLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
            [[cell detailTextLabel] setTextAlignment:NSTextAlignmentCenter];
            [self updateConnectionDetailCell:cell];
        }
    }
    else if (indexPath.section == 2){
        if(indexPath.row == 0){
            [[cell textLabel] setText:@"SETUP HELP"];
            [[cell textLabel] setTextColor:rainbow];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
            [[cell detailTextLabel] setText:@""];
        }
        else{
            [[cell textLabel] setText:@"HOVERPAD REQUIRES 2 PARTS\n • iOS APP (✔︎)\n • DESKTOP APP (FREE @ http://hoverpad.wtf)\n\nCONNECTION PROCESS:\n • BEGIN SCAN ON BOTH iOS & DESKTOP APPS\n • WAIT 3-10 SECONDS FOR CONNECTION\n • CUSTOMIZE ANY PREFERENCES ON DESKTOP\n\nTROUBLESHOOTING\n • IF CONNECTION BREAKS BEFORE PROPER EXIT, GO TO PHONE'S SETTINGS, TURN BLUETOOTH OFF & ON, WAITING A FEW SECONDS"];
            [cell setFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, 180)];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
        }
    }
    else if (indexPath.section == 3){
        if(indexPath.row == 0){
            [[cell textLabel] setText:@"TUTORIAL"];
            [[cell detailTextLabel] setText:@""];
            [[cell textLabel] setTextColor:rainbow];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        }
        else{
            
        }
    }
    else if (indexPath.section == 4){
        [[cell textLabel] setText:@"OKAY"];
        [[cell textLabel] setTextColor:rainbow];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [[cell detailTextLabel] setText:@""];
    }
    return cell;
}

@end
