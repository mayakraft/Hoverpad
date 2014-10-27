//
//  DetailCell.m
//  Hoverpad
//
//  Created by Robby on 10/27/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "DetailCell.h"

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if 1
#define PADDING 20
#else
#define PADDING 50
#endif

#define CUSTOM_FONT @"Lato-Light"
#define GRAY [UIColor colorWithWhite:.75 alpha:1.0]

@implementation DetailCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.borderWidth = 1.0f + IS_IPAD();
        if([self textLabel]){
            [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f + 43.0f*IS_IPAD()]];
            [self.textLabel setBackgroundColor:[UIColor clearColor]];
            [self.textLabel setTextColor:GRAY];
            [self.textLabel setNumberOfLines:0];
            [self.textLabel sizeToFit];
        }
        if([self detailTextLabel]){
            [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f + 43.0f*IS_IPAD()]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.detailTextLabel setTextColor:GRAY];
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

@end
