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
        self.layer.borderWidth = 1.0f + IS_IPAD();
        if([self textLabel]){
            [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f + 43.0f*IS_IPAD()]];
            [self.textLabel setBackgroundColor:[UIColor clearColor]];
            [self.textLabel setTextColor:[UIColor lightGrayColor]];
            [self.textLabel setNumberOfLines:0];
            [self.textLabel sizeToFit];
        }
        if([self detailTextLabel]){
            [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f + 43.0f*IS_IPAD()]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.detailTextLabel setTextColor:[UIColor lightGrayColor]];
            [self.detailTextLabel setNumberOfLines:0];
            [self.detailTextLabel sizeToFit];
        }
        [self layoutSubviews];
    }
    return self;
}
-(void) layoutSubviews{
    [super layoutSubviews];
    [self setBackgroundColor:[UIColor blackColor]];
    if([self textLabel]){
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.bounds.size.width-PADDING, self.textLabel.frame.size.height);
    }
    if([self detailTextLabel]){
        self.detailTextLabel.frame = CGRectMake(PADDING, PADDING, self.bounds.size.width-PADDING*2, 30.0f + 43.0f*IS_IPAD());//self.detailTextLabel.frame.size.height);
        [self.detailTextLabel setTextAlignment:NSTextAlignmentRight];
    }
}

- (void)setFrame:(CGRect)frame {
    frame.origin.x += PADDING;
    frame.size.width = [[UIScreen mainScreen] bounds].size.height - 2 * PADDING;
    [super setFrame:frame];
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//    // Configure the view for the selected state
//}

@end
