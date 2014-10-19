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

-(void) cycleColor{
    for(int i = 0; i < NUM_CELLS; i++){
        float hue = ((float)(4-i)/NUM_CELLS) + cycle;
        if(hue > 1.0) hue -= 1.0;
        if(hue < 0.0) hue += 1.0;
        UIColor *rainbow = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
        Cell *cell = (Cell*)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
        if(cell){
            [[cell textLabel] setTextColor:rainbow];
            [[cell layer] setBorderColor:rainbow.CGColor];
        }
        if(_cellExpanded[i]){
            Cell *cell = (Cell*)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:i]];
            if(cell){
//                [[cell textLabel] setTextColor:rainbow];
                [[cell layer] setBorderColor:rainbow.CGColor];
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
//            [[cell textLabel] setTextColor:rainbow];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
            [[cell textLabel] setNumberOfLines:2];
            [[cell detailTextLabel] setText:@""];
        }
    }
    else if (indexPath.section == 1){
        if(indexPath.row == 0){
            [[cell textLabel] setText:@"CONNECTION STATUS"];
            [[cell textLabel] setTextColor:rainbow];
            [[cell detailTextLabel] setText:@"NONE"];
            [[cell detailTextLabel] setTextColor:[UIColor redColor]];
        }
        else{
            [cell setFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, 180)];
            [[cell textLabel] setText:@"NOT CONNECTED OR SEARCHING\nTAP HERE TO BEGIN SEARCHING\n(OR TAP PENTAGON ON MAIN WINDOW)"];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
            [[cell textLabel] setNumberOfLines:7];
            [[cell detailTextLabel] setText:@""];
            [[cell detailTextLabel] setTextColor:[UIColor redColor]];
            [[cell detailTextLabel] setNumberOfLines:4];
        }
//        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"noise"] isEqualToString:@"white"])
//            [[cell detailTextLabel] setText:@""];
//        else
    }
    else if (indexPath.section == 2){
        if(indexPath.row == 0){
            [[cell textLabel] setText:@"SETUP TUTORIAL"];
            [[cell textLabel] setTextColor:rainbow];
            [[cell detailTextLabel] setText:@""];
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        }
        else{
            [[cell textLabel] setText:@"HOVERPAD REQUIRES 2 PARTS\n • iOS APP (✔︎)\n • DESKTOP APP (FREE @ http://hoverpad.wtf)\n\n1. BEGIN SCAN ON BOTH iOS & DESKTOP APPS\n2. WAIT 3-10 SECONDS FOR CONNECTION\n3. CUSTOMIZE PREFERENCES ON DESKTOP APP"];
            [[cell textLabel] setNumberOfLines:7];
            [cell setFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, 180)];
            [[cell textLabel] setFont:[UIFont fontWithName:@"Lato-Light" size:20.0f]];
        }
//        [[cell textLabel] setText:@"theme"];
//        [[cell detailTextLabel] setText:[[[[Colors sharedColors] themes] objectForKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]] objectForKey:@"title"]];
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
        [[cell detailTextLabel] setText:@""];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
//        [[cell textLabel] setText:@"themes"];
//        [[cell detailTextLabel] setText:@"$.99"];
//        [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
    }
//    else if (indexPath.section == 5){
//        SKProduct * product = (SKProduct *) _products[0];
//        [_priceFormatter setLocale:product.priceLocale];
//        NSLog(@"%@",product);
//        [[cell textLabel] setText:[_priceFormatter stringFromNumber:product.price]];
//        [[cell detailTextLabel] setText:@""];
//        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
//    }
    else{
        [[cell textLabel] setText:@"expanded cell?"];
        [[cell detailTextLabel] setText:@""];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    }
    return cell;
}

@end
