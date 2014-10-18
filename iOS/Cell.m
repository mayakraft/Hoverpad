//
//  Cell.m
//  Autonaut
//
//  Created by Robby on 6/3/13.
//  Copyright (c) 2013 robbykraft. All rights reserved.
//

#import "Cell.h"
#import <QuartzCore/QuartzCore.h>

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if 1
#define PADDING 20
#else
#define PADDING 50
#endif

#define CUSTOM_FONT @"Lato-Light"

@implementation Cell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.layer.borderWidth = 1.0f;
        [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f]];
        [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f]];
        if(IS_IPAD())
        {
            self.layer.borderWidth = 2.0f;
            [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:66.0f]];
            [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:66.0f]];
        }
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        [self setBackgroundColor:[UIColor blackColor]];
        [[self textLabel] setTextColor:[UIColor lightGrayColor]];
        [self.detailTextLabel setTextColor:[UIColor lightGrayColor]];
    }
    return self;
}
-(void) layoutSubviews{
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.bounds.size.width-PADDING, self.textLabel.frame.size.height);
    [self setBackgroundColor:[UIColor blackColor]];
//    [[self textLabel] setTextColor:[UIColor lightGrayColor]];
}

- (void)setFrame:(CGRect)frame {

    frame.origin.x += PADDING;
    frame.size.width = [[UIScreen mainScreen] bounds].size.height - 2 * PADDING;
    frame.size.height = PADDING * 2;
    [super setFrame:frame];

    self.layer.borderWidth = 1.0f;
    [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f]];
    [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f]];
    if(IS_IPAD()) {
        self.layer.borderWidth = 2.0f;
        [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:66.0f]];
        [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:66.0f]];
    }
//    [self.detailTextLabel setTextColor:[UIColor lightGrayColor]];
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
    
//    [self.textLabel setHighlightedTextColor:[UIColor whiteColor]];
//    [self.detailTextLabel setHighlightedTextColor:[UIColor whiteColor]];
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//    // Configure the view for the selected state
//}

@end
