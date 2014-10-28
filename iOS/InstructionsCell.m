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

#define GRAY [UIColor colorWithWhite:.75 alpha:1.0]

@implementation InstructionsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.borderWidth = 1.0f + IS_IPAD();
        if([self textLabel]){
            [self.textLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
            [self.textLabel setBackgroundColor:[UIColor clearColor]];
            [self.textLabel setTextColor:GRAY];
            [self.textLabel setNumberOfLines:0];
            [self.textLabel sizeToFit];
        }
        if([self detailTextLabel]){
            [self.detailTextLabel setFont:[UIFont fontWithName:CUSTOM_FONT size:30.0f + 30.0f*IS_IPAD()]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.detailTextLabel setTextColor:GRAY];
            [self.detailTextLabel setNumberOfLines:0];
            [self.detailTextLabel sizeToFit];
        }
        _textLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, 450+450*IS_IPAD(), self.frame.size.width-2*PADDING, 200+200*IS_IPAD())];
        [_textLabel2 setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
        [_textLabel2 setBackgroundColor:[UIColor clearColor]];
        [_textLabel2 setTextColor:GRAY];
        [_textLabel2 setNumberOfLines:0];
        [_textLabel2 setTextAlignment:NSTextAlignmentCenter];
//        [_textLabel2 sizeToFit];
        [self addSubview:_textLabel2];

        _textLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(PADDING+self.frame.size.width*.33, 700+700*IS_IPAD(), self.frame.size.width*.66-2*PADDING, 200+200*IS_IPAD())];
        [_textLabel3 setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
        [_textLabel3 setBackgroundColor:[UIColor clearColor]];
        [_textLabel3 setTextColor:GRAY];
        [_textLabel3 setNumberOfLines:0];
        [_textLabel3 setTextAlignment:NSTextAlignmentCenter];
//        [_textLabel3 sizeToFit];
        [self addSubview:_textLabel3];
        
        _textLabel4 = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, 950+950*IS_IPAD(), self.frame.size.width-2*PADDING, 200+200*IS_IPAD())];
        [_textLabel4 setFont:[UIFont fontWithName:CUSTOM_FONT size:20.0f + 20.0f*IS_IPAD()]];
        [_textLabel4 setBackgroundColor:[UIColor clearColor]];
        [_textLabel4 setTextColor:GRAY];
        [_textLabel4 setNumberOfLines:0];
        [_textLabel4 setTextAlignment:NSTextAlignmentCenter];
//        [_textLabel4 sizeToFit];
        [self addSubview:_textLabel4];

        
        _imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grip.png"]];
        [_imageView2 setCenter:CGPointMake(self.frame.size.width*.5, 375+375*IS_IPAD())];
        CGSize newSize2 = CGSizeMake(self.frame.size.width*.7, ceil(self.frame.size.width*.7 * _imageView2.frame.size.height / _imageView2.frame.size.width));
        [[self imageView2] setBounds:CGRectMake(0, 0, newSize2.width, newSize2.height)];
        [self addSubview:_imageView2];
//        [[self imageView2] setContentMode:UIViewContentModeScaleAspectFill];

        _imageView3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leg.png"]];
//        [_imageView3 setCenter:CGPointMake(self.frame.size.width*.5, 375+375*IS_IPAD())];
        CGSize newSize3 = CGSizeMake(self.frame.size.width*.4, ceil(self.frame.size.width*.4 * _imageView3.frame.size.height / _imageView3.frame.size.width));
        [[self imageView3] setBounds:CGRectMake(0, 0, newSize3.width, newSize3.height)];
        [[self imageView3] setFrame:CGRectMake(PADDING*2, 650 + 650*IS_IPAD(), _imageView3.frame.size.width, _imageView3.frame.size.height)];
        [self addSubview:_imageView3];

        [self layoutSubviews];
    }
    return self;
}
-(void) layoutSubviews{
    [super layoutSubviews];
    [self setBackgroundColor:[UIColor blackColor]];
    if([self textLabel]){
        self.textLabel.frame = CGRectMake(PADDING, PADDING*2, self.bounds.size.width-PADDING*2, 200+200*IS_IPAD());
//        [[self textLabel] setTextAlignment:NSTextAlignmentCenter];
        [[self textLabel] setText:@"\nFLASH THE SCREEN (TAP THE BLACK PART):\nDEVICE BECOMES RE-ALIGNED\n\nDO THIS OFTEN!\n ‣ WHENEVER YOU BRING ALIGNMENT TO ZERO, IT USUALLY IS OFF BY A LITTLE BIT"];
    }
    if([self detailTextLabel]){
        self.detailTextLabel.frame = CGRectMake(PADDING, self.detailTextLabel.frame.origin.y, self.bounds.size.width-PADDING*2, self.detailTextLabel.frame.size.height);
        [[self detailTextLabel] setText:@"RE-STABILIZATION SYSTEM"];
        [[self detailTextLabel] setFrame:CGRectMake(PADDING, PADDING, self.frame.size.width-PADDING*2, 40 + 60*IS_IPAD())];
//        [[self detailTextLabel] setTextAlignment:NSTextAlignmentCenter];
    }
    if([self textLabel2]){
        [[self textLabel2] setText:@"GAMEPAD\n\n‣ PITCH=FORWARD/BACK\nAND EITHER:\n‣ ROLL=STRAFE  &  YAW=TURN\n‣ ROLL=TURN  &  YAW=STRAFE"];
    }
    if([self textLabel3]){
        [[self textLabel3] setText:@"SKATEBOARD/SKIING\n(ROLLED UP PANTS CUFFS)\n\n‣ YAW=FORWARD/BACK\n‣ PITCH=TURN"];
    }
    if([self textLabel4]){
        [[self textLabel4] setText:@"MORE IDEAS:\nFAKE STEERING WHEEL, BIKE HANDLEBARS, STRAP IT TO YOUR DOG (NOT LIABLE), BE CREATIVE!"];
    }
    if([self imageView2]){
    }
//    @"[1] HOLD LIKE A CAFETERIA TRAY WITH YOUR THUMBS OVER THE SCREEN\n ‣ MAP PITCH TO FORWARD/BACK\n ‣ MAP ROLL TO EITHER STRAFE OR TURN DEPENDING ON PREFERENCE\n ‣ WHEN INTENDING TO STOP, RETURN ORIENTATION TO WHAT YOU BELIEVE TO BE THE HOME ORIENTATION, PRESS AND RELEASE THE SCREEN\n\n[2] STRAP TO YOUR LEG, LEAN LIKE YOU'RE ON A SKATEBOARD\n ‣ DECREASE THE ANGLE OF RESPONSE IN THE DESKTOP PREFERENCES\n\n[3] ATTACH TO YOUR DOG\n(NOT LIABLE)\n\n[4] GET CREATIVE"
}

- (void)setFrame:(CGRect)frame {
    frame.origin.x += PADDING;
    frame.size.width = [[UIScreen mainScreen] bounds].size.height - 2 * PADDING;
    [super setFrame:frame];
}

@end
