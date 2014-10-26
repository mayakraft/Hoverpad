//
//  InstructionsCell.m
//  Hoverpad
//
//  Created by Robby on 10/26/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "InstructionsCell.h"

#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if 1
#define PADDING 20
#else
#define PADDING 50
#endif

#define CUSTOM_FONT @"Lato-Light"

@implementation InstructionsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.borderWidth = 1.0f + IS_IPAD();
        if([self textLabel]){
            [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
            [self.textLabel setBackgroundColor:[UIColor clearColor]];
            [self.textLabel setTextColor:[UIColor lightGrayColor]];
            [self.textLabel setNumberOfLines:0];
            [self.textLabel sizeToFit];
        }
        if([self detailTextLabel]){
            [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f + 30.0f*IS_IPAD()]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.detailTextLabel setTextColor:[UIColor lightGrayColor]];
            [self.detailTextLabel setNumberOfLines:0];
            [self.detailTextLabel sizeToFit];
        }
        _textLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, 500+500*IS_IPAD(), self.frame.size.width-2*PADDING, 200+200*IS_IPAD())];
        [_textLabel2 setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
        [_textLabel2 setBackgroundColor:[UIColor clearColor]];
        [_textLabel2 setTextColor:[UIColor lightGrayColor]];
        [_textLabel2 setNumberOfLines:0];
        [_textLabel2 setTextAlignment:NSTextAlignmentCenter];
        //        [_textLabel2 sizeToFit];
        [self addSubview:_textLabel2];
        
        _imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grip.png"]];
        [_imageView2 setCenter:CGPointMake(self.frame.size.width*.5, 150+150*IS_IPAD())];
//        [_imageView2 setContentMode:UIViewContentModeScaleAspectFill];
        [self addSubview:_imageView2];
        
        [self layoutSubviews];
    }
    return self;
}
-(void) layoutSubviews{
    [super layoutSubviews];
    [self setBackgroundColor:[UIColor blackColor]];
    if([self textLabel]){
        self.textLabel.frame = CGRectMake(PADDING, 300+300*IS_IPAD(), self.bounds.size.width-PADDING*2, 100+100*IS_IPAD());
//        [[self textLabel] setTextAlignment:NSTextAlignmentCenter];
        [[self textLabel] setText:@"PITCH->FORWARD/BACK\n -EITHER- ROLL->STRAFE YAW->TURN\n -OR- YAW->STRAFE ROLL->TURN"];
    }
    if([self detailTextLabel]){
        self.detailTextLabel.frame = CGRectMake(PADDING, self.detailTextLabel.frame.origin.y, self.bounds.size.width-PADDING*2, self.detailTextLabel.frame.size.height);
        [[self detailTextLabel] setText:@""];
        [[self detailTextLabel] setFrame:CGRectMake(PADDING, 0, self.frame.size.width-PADDING*2, 40 + 60*IS_IPAD())];
//        [[self detailTextLabel] setTextAlignment:NSTextAlignmentCenter];
    }
    if([self textLabel2]){
        [[self textLabel2] setText:@"YAW->FORWARD/BACK PITCH->TURN"];
    }
    if([self imageView2]){
        [[self imageView2] setImage:[UIImage imageNamed:@"grip.png"]];
    }
}

- (void)setFrame:(CGRect)frame {
    frame.origin.x += PADDING;
    frame.size.width = [[UIScreen mainScreen] bounds].size.height - 2 * PADDING;
    [super setFrame:frame];
}

@end
