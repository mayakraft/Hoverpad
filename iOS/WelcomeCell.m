//
//  TitleCell.m
//  Hoverpad
//
//  Created by Robby on 10/26/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "WelcomeCell.h"

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if 1
#define PADDING 20
#else
#define PADDING 50
#endif

#define CUSTOM_FONT @"Lato-Light"
#define GRAY [UIColor colorWithWhite:.75 alpha:1.0]

@implementation WelcomeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.borderWidth = 1.0f + IS_IPAD();
        if([self textLabel]){
            [[self textLabel] setText:@"HOVERPAD IS A WIRELESS GAME CONTROLLER\n\nIT REQUIRES 2 APPS"];
            [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
            [self.textLabel setBackgroundColor:[UIColor clearColor]];
            [self.textLabel setTextColor:GRAY];
            [self.textLabel setNumberOfLines:0];
            [self.textLabel sizeToFit];
        }
        if([self detailTextLabel]){
            [[self detailTextLabel] setText:@""];
        }
        _textLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, 300+300*IS_IPAD(), self.frame.size.width-2*PADDING, 200+200*IS_IPAD())];
        [[self textLabel2] setText:@"\nGET THE OSX APP AT HTTP://HOVERPAD.WTF\n\nPROCEED TO 'CONNECTION STATUS'"];
        [_textLabel2 setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
        [_textLabel2 setBackgroundColor:[UIColor clearColor]];
        [_textLabel2 setTextColor:GRAY];
        [_textLabel2 setNumberOfLines:0];
        [_textLabel2 sizeToFit];
        [_textLabel2 setFrame:CGRectMake(_textLabel2.frame.origin.x, _textLabel2.frame.origin.y, self.frame.size.width-2*PADDING, _textLabel2.frame.size.height)];
        [_textLabel2 setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_textLabel2];

        _imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(PADDING, 150+150*IS_IPAD(), self.frame.size.width-2*PADDING, (self.frame.size.width-2*PADDING)/3.5)];
        [[self imageView2] setImage:[UIImage imageNamed:@"devices.png"]];
        [self addSubview:_imageView2];

        [self layoutSubviews];
    }
    return self;
}
-(void) layoutSubviews{
    [super layoutSubviews];
    [self setBackgroundColor:[UIColor blackColor]];
    if([self textLabel]){
        self.textLabel.frame = CGRectMake(PADDING, PADDING*2, self.bounds.size.width-PADDING*2, self.textLabel.frame.size.height);
        [[self textLabel] setTextAlignment:NSTextAlignmentCenter];
    }
}

- (void)setFrame:(CGRect)frame {
    frame.origin.x += PADDING;
    frame.size.width = [[UIScreen mainScreen] bounds].size.height - 2 * PADDING;
    [super setFrame:frame];
}


@end
