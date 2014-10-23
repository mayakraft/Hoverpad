//
//  View.h
//  Hoverpad
//
//  Created by Robby on 10/9/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface ScreenView : GLKView

@property (nonatomic) BOOL isScreenTouched;
@property BOOL isButtonTouched;
@property (nonatomic) NSUInteger state;

@property float aspectRatio;
@property float fieldOfView;

@property GLKMatrix4 projectionMatrix;
@property GLKMatrix4 deviceOrientation;

-(void) draw;

@end
