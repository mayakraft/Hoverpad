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
    }
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self) {
        _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
    }
    return self;
}
-(id)  init{
    self = [super init];
    if(self){
        _cellExpanded = calloc(NUM_CELLS, sizeof(BOOL));
    }
    return self;
}
-(void) dealloc{
    free(_cellExpanded);
}

- (void)viewDidLoad{
    NSLog(@"Entering Settings viewDidLoad");
    [self setBackgroundColor:[UIColor clearColor]];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    //Cell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Cell *cell = [[Cell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    UIColor *rainbow = [UIColor colorWithHue:((float)(4-indexPath.section)/NUM_CELLS) saturation:1.0 brightness:1.0 alpha:1.0];
    
    [[cell layer] setBorderColor:rainbow.CGColor];
    
    cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y-indexPath.row*10, cell.frame.size.width, cell.frame.size.height);
    
    if(indexPath.section == 0){
        [[cell textLabel] setTextColor:rainbow];
        [[cell textLabel] setText:@"HOVERPAD"];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
//        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"retina"] integerValue] == 1)
//            [[cell detailTextLabel] setText:@"no"];
//        else
            [[cell detailTextLabel] setText:@""];
    }
    else if (indexPath.section == 1){
        [[cell textLabel] setText:@"CONNECTION STATUS"];
        [[cell detailTextLabel] setText:@"NONE"];
//        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"noise"] isEqualToString:@"white"])
//            [[cell detailTextLabel] setText:@""];
//        else
    }
    else if (indexPath.section == 2){
        [[cell textLabel] setText:@"HELP ME OUT. WHAT IS THIS?"];
        [[cell detailTextLabel] setText:@""];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
//        [[cell textLabel] setText:@"theme"];
//        [[cell detailTextLabel] setText:[[[[Colors sharedColors] themes] objectForKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]] objectForKey:@"title"]];
    }
    else if (indexPath.section == 3){
        [[cell textLabel] setText:@"PREFERENCES"];
        [[cell detailTextLabel] setText:@""];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    }
    else if (indexPath.section == 4){
        [[cell textLabel] setText:@"OKAY"];
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
