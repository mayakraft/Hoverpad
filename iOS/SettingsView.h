//
//  SettingsView.h
//  Autonaut
//
//  Created by Robby on 6/4/13.
//  Copyright (c) 2013 robbykraft. All rights reserved.
//

#import <UIKit/UIKit.h>

// landscape tableView for portrait-oriented apps

@interface SettingsView : UITableView <UITableViewDataSource, UITableViewDelegate>

@property BOOL *cellExpanded;

@property (nonatomic) NSInteger connectionState;
@property (nonatomic) NSInteger hardwareState;

-(void) fakeDealloc;

-(void) flashCommunicationLight;

@property (weak) UIImage *info1;
@property (weak) UIImage *info2;
@property (weak) UIImage *info3;

@end
