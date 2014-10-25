//
//  View.m
//  Hoverpad
//
//  Created by Robby on 10/9/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "ScreenView.h"
#import <OpenGLES/ES1/gl.h>

#define FOV_MIN 1
#define FOV_MAX 155
#define Z_NEAR 0.1f
#define Z_FAR 100.0f

void glDrawSquare(){
    static const GLfloat _unit_square[] = {
        -0.5f, 0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f };
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, _unit_square);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableClientState(GL_VERTEX_ARRAY);
}
void glDrawRectOutline(CGRect rect){
    static const GLfloat _unit_square_outline[] = {
        -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f, -0.5f, -0.5f };
    glPushMatrix();
    glTranslatef(rect.origin.x, rect.origin.y, 0.0);
    glScalef(rect.size.width, rect.size.height, 1.0);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, _unit_square_outline);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    glDisableClientState(GL_VERTEX_ARRAY);
    glPopMatrix();
}

typedef enum : NSUInteger {
    buttonDeadOnTheGround,
    buttonSearching,
    buttonRise,
    buttonFall,
} ButtonState;

@interface ScreenView (){
    NSDate *startTime, *animationStateStart;
    float y;
    ButtonState buttonState;
    GLfloat groundColor[4], screenColor[4];
    int litFace;  // -1 for no face
    NSTimer *screenFadeAnimation;
}

@end

@implementation ScreenView

-(id)initWithFrame:(CGRect)frame context:(EAGLContext *)context{
    self = [super initWithFrame:frame context:context];
    if(self){
        [self initOpenGL];
    }
    return self;
}
#pragma mark- THINKY STUFF
-(void) setIsScreenTouched:(BOOL)isScreenTouched{
    _isScreenTouched = isScreenTouched;
// flash screen
    if(isScreenTouched){
        // rapid touch- invalidate previous tap and fade animation
        if(screenFadeAnimation){
            [screenFadeAnimation invalidate];
            screenFadeAnimation = nil;
        }
        screenColor[0] = screenColor[1] = screenColor[2] = 1.0f;
    }
// fade out screen flash
    if(!isScreenTouched){
        if(screenFadeAnimation){
            // this shouldn't ever happen, but if animation is still going, invalidate it and start a new one
            [screenFadeAnimation invalidate];
            screenFadeAnimation = nil;
        }
        screenColor[0] = screenColor[1] = screenColor[2] = 1.0f;
        screenFadeAnimation = [NSTimer scheduledTimerWithTimeInterval:1/30.0 target:self selector:@selector(screenFadeLoop) userInfo:nil repeats:YES];
    }
}
-(void) screenFadeLoop{
    float brightness = screenColor[0];
    brightness -= .15;
// decrease brightness until zero, whereupon kill the animation loop
    if(brightness <= 0){
        screenColor[0] = screenColor[1] = screenColor[2] = 0.0f;
        [screenFadeAnimation invalidate];
        screenFadeAnimation = nil;
    }
    else{
        screenColor[0] = screenColor[1] = screenColor[2] = brightness;
    }
}
/*
 * 0 PeripheralConnectionStateDisconnected,
 * 1 PeripheralConnectionStateBooting,
 * 2 PeripheralConnectionStateScanning,
 * 3 PeripheralConnectionStateConnected,
 * 4 PeripheralConnectionStateDisconnecting
 */
-(void) setState:(NSUInteger)state{
// scanning
    if(state == 2){
        buttonState = buttonSearching;
        animationStateStart = [NSDate date];
    }
    else{
        litFace = -1;
    }
// connected
    if(state == 3){
        buttonState = buttonRise;
        animationStateStart = [NSDate date];
    }
    if(state == 4){
// disconnecting from having been scanning
        if(_state == 2){
            buttonState = buttonDeadOnTheGround;
            animationStateStart = nil;
        }
// disconnecting from having been connected
        else{
            buttonState = buttonFall;
            animationStateStart = [NSDate date];
        }
    }
// disconnected having skipped over "disconnecting" state
    if (state == 0 && _state != 4){
// disconnected from having been connected
        if(_state == 3 && buttonState != buttonFall){
            buttonState = buttonFall;
            animationStateStart = [NSDate date];
        }
        else{
            buttonState = buttonDeadOnTheGround;
            animationStateStart = nil;
        }
    }
    _state = state;
}

-(void) update{
    if(animationStateStart){
        if(buttonState == buttonSearching) {
            litFace = ((int)(-[animationStateStart timeIntervalSinceNow]*10))%5;
        }
        if(buttonState == buttonRise || buttonState == buttonFall){
            float x = -[animationStateStart timeIntervalSinceNow]*4;
            float s = .5;
            // y = 10-(10/((x+.95)^2) * sin(2(x+.95));
            y = s-(s/powf((x+.95),2)) * sin(2*(x+.95));
            if(y < 0.0f) y = 0.0f;
            if(buttonState == buttonFall){
                y = .5 - y;
            }
        }
        else{
            y = 0.0f;
        }
        float darkness = 0.0;
        if(buttonState == buttonRise)
            darkness = -[animationStateStart timeIntervalSinceNow]*2;
        else if(buttonState == buttonFall || buttonState == buttonSearching)
            darkness = 1.0+[animationStateStart timeIntervalSinceNow]*4;
        
        if(darkness > 1.0) darkness = 1.0;
        if(darkness < 0.0) darkness = 0.0;
        groundColor[0] = groundColor[1] = groundColor[2] = darkness;
        
        if(-[animationStateStart timeIntervalSinceNow] > 5 && buttonState != buttonSearching){
            animationStateStart = nil;
        }
    }
}

#pragma mark- DRAWEY STUFF

-(void)initOpenGL{
    _aspectRatio = self.frame.size.width/self.frame.size.height;
//    _fieldOfView = 45 + 45 * atanf(_aspectRatio); // hell ya
    _fieldOfView = 40;
    [self rebuildProjectionMatrix];
    
    static const GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    
    groundColor[0] = groundColor[1] = groundColor[2] = 0.0f;
    groundColor[3] = 1.0f;
    screenColor[0] = screenColor[1] = screenColor[2] = 0.0f;
    screenColor[3] = 1.0f;
    
    litFace = -1;
    
    GLfloat pos1[] = {0.0f, 0.0f, 4.0f, 1.0f};
    glEnable(GL_CULL_FACE);
    glCullFace(GL_FRONT);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, white);
//    glLightfv(GL_LIGHT0, GL_SPECULAR, specular);
    glLightfv(GL_LIGHT0, GL_POSITION, pos1);
//    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 40);
//    glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, .0005);
    GLfloat spot_direction[] = { 0.0, 0.0, -1.0 };
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, spot_direction);
    
    glShadeModel(GL_SMOOTH);
//    glMateriali(GL_FRONT_AND_BACK, GL_SHININESS, 20);
    startTime = [NSDate date];
}
-(void)rebuildProjectionMatrix{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    GLfloat frustum = Z_NEAR * tanf(_fieldOfView*0.00872664625997);  // pi/180/2
    _projectionMatrix = GLKMatrix4MakeFrustum(-frustum, frustum, -frustum/_aspectRatio, frustum/_aspectRatio, Z_NEAR, Z_FAR);
    glMultMatrixf(_projectionMatrix.m);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glMatrixMode(GL_MODELVIEW);
}

-(void) draw{
    [self update];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glPushMatrix();
        glMultMatrixf(_deviceOrientation.m);
        glPushMatrix();
            glRotatef(-90, 0, 0, 1);
            if(groundColor[0] != 0.0)// && !_isScreenTouched)
                [self glDrawTable];
            glPushMatrix();
                glTranslatef(0, 0, y);
                glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
                [self glDrawPentagonTriangles:(buttonState == buttonRise)];
            glPopMatrix();
        glPopMatrix();
    glPopMatrix();
        
    glDisable(GL_LIGHTING);
    glDisable(GL_LIGHT0);
    [self enterOrthographic];
        glLineWidth(4.0);
        glColor4f(screenColor[0], screenColor[1], screenColor[2], screenColor[3]);
        glDrawRectOutline(CGRectMake(self.frame.size.width*.5, self.frame.size.height*.5, self.frame.size.width*.99, .99*self.frame.size.height));
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
//        if(!_isScreenTouched){
            glPushMatrix();
                glTranslatef(self.frame.size.width*.933, self.frame.size.height*.5, 0.0);
                glScalef(40.0f, 40.0f, 1.0f);
                glColor4f(0.2f, 0.2f, 0.2f, 1.0f);
                glPushMatrix();
                    glScalef(.15f, 1.0f, 1.0f);
                    glDrawSquare();
                glPopMatrix();
                glPushMatrix();
                    glTranslatef(.25f, 0.0f, 0.0f);
                    glScalef(.15f, 1.0f, 1.0f);
                    glDrawSquare();
                glPopMatrix();
            
                glPushMatrix();
                    glTranslatef(-.25f, 0.0f, 0.0f);
                    glScalef(.15f, 1.0f, 1.0f);
                    glDrawSquare();
                glPopMatrix();
            glPopMatrix();
//        }
    [self exitOrthographic];
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
}

-(void) glDrawTable{
    float s = 1.3;
//    static const GLfloat centerVertices[] = {
//        0.0f, 0.0f, -0.1f,
//        0.0f, 1.0f, -0.1f,
//        .951f, .309f, -0.1f,
//        .5878, -.809, -0.1f,
//        -.5878, -.809, -0.1f,
//        -.951f, .309f, -0.1f,
//        0.0f, 1.0f, -0.1f
//    };
//    static const GLfloat centerNormals[] = {
//        0.0f, 0.0f, 1.0f,
//        0.0f, 0.0f, 1.0f,
//        0.0f, 0.0f, 1.0f,
//        0.0f, 0.0f, 1.0f,
//        0.0f, 0.0f, 1.0f,
//        0.0f, 0.0f, 1.0f,
//        0.0f, 0.0f, 1.0f
//    };
    GLfloat tableVertices[] = {
        0.0f, 1.0f, -0.1f,
        0.0f, s*1.0f, -0.1f,
        .951f, .309f, -0.1f,
        s*.951f, s*.309f, -0.1f,
        .5878, -.809, -0.1f,
        s*.5878, s*-.809, -0.1f,
        -.5878, -.809, -0.1f,
        s*-.5878, s*-.809, -0.1f,
        -.951f, .309f, -0.1f,
        s*-.951f, s*.309f, -0.1f,
        0.0f, 1.0f, -0.1f,
        0.0f, s*1.0f, -0.1f
    };
    static const GLfloat tableNormals[] = {
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, -1.0f
    };
    static const GLfloat black[] = {0.0, 0.0, 0.0, 1.0};
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, black);
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, groundColor);
    glVertexPointer(3, GL_FLOAT, 0, tableVertices);
    glNormalPointer(GL_FLOAT, 0, tableNormals);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 12);
//    glVertexPointer(3, GL_FLOAT, 0, centerVertices);
//    glNormalPointer(GL_FLOAT, 0, centerNormals);
//    glDrawArrays(GL_TRIANGLE_FAN, 0, 7);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
}

-(void) glDrawPentagonTriangles:(BOOL) lit{
//    static const GLfloat tri1[] = { // red
//        0.0f, 0.0f, 0.1f,        0.0f, 0.0f, 1.0f,
//        0.0f, 1.0f, 0.1f,        0.0f, 0.0f, 1.0f,
//        .951f, .309f, 0.1f,        0.0f, 0.0f, 1.0f,
//        0.0f, 1.0f, -0.1f,        .587f, .809f, 0.0f,
//        .951f, .309f, -0.1f,        .587f, .809f, 0.0f,
//        0.0f, 0.0f, -0.1f,        0.0f, 0.0f, -1.0f
//    };
    static const GLfloat tri1[] = { // red
        0.0f, 0.0f, 0.1f,
        0.0f, 1.0f, 0.1f,
        .951f, .309f, 0.1f,
        0.0f, 1.0f, -0.1f,
        .951f, .309f, -0.1f,
        0.0f, 0.0f, -0.1f
    };
    static const GLfloat tri2[] = {  // yellow
        0.0f, 0.0f, 0.1f,
        .951f, .309f, 0.1f,
        .5878, -.809, 0.1f,
        .951f, .309f, -0.1f,
        .5878, -.809, -0.1f,
        0.0f, 0.0f, -0.1f
    };
    static const GLfloat tri3[] = {
        0.0f, 0.0f, 0.1f,
        .5878, -.809, 0.1f,
        -.5878, -.809, 0.1f,
        .5878, -.809, -0.1f,
        -.5878, -.809, -0.1f,
        0.0f, 0.0f, -0.1f
    };
    static const GLfloat tri4[] = {
        0.0f, 0.0f, 0.1f,
        -.5878, -.809, 0.1f,
        -.951f, .309f, 0.1f,
        -.5878, -.809, -0.1f,
        -.951f, .309f, -0.1f,
        0.0f, 0.0f, -0.1f
    };
    static const GLfloat tri5[] = {
        0.0f, 0.0f, 0.1f,
        -.951f, .309f, 0.1f,
        0.0f, 1.0f, 0.1f,
        -.951f, .309f, -0.1f,
        0.0f, 1.0f, -0.1f,
        0.0f, 0.0f, -0.1f
    };

    
    static const GLfloat tri1normal[] = {
        0.0f, 0.0f, 1.0f,
        .587f, .809f, 0.5f,
        .587f, .809f, 0.5f,
        .587f, .809f, -0.5f,
        .587f, .809f, -0.5f,
        0.0f, 0.0f, -1.0f
    };
    static const GLfloat tri2normal[] = {
        0.0f, 0.0f, 1.0f,
        .951f, -.301f, 0.5f,
        .951f, -.301f, 0.5f,
        .951f, -.301f, -0.5f,
        .951f, -.301f, -0.5f,
        0.0f, 0.0f, -1.0f
    };
    static const GLfloat tri3normal[] = {
        0.0f, 0.0f, 1.0f,
        0.0f, -1.0f, 0.5f,
        0.0f, -1.0f, 0.5f,
        0.0f, -1.0f, -0.5f,
        0.0f, -1.0f, -0.5f,
        0.0f, 0.0f, -1.0f
    };
    
    static const GLfloat tri4normal[] = {
        0.0f, 0.0f, 1.0f,
        -.951f, -.301f, 0.5f,
        -.951f, -.301f, 0.5f,
        -.951f, -.301f, -0.5f,
        -.951f, -.301f, -0.5f,
        0.0f, 0.0f, -1.0f
    };
    
    static const GLfloat tri5normal[] = {
        0.0f, 0.0f, 1.0f,
        -.587f, .809f, 0.5f,
        -.587f, .809f, 0.5f,
        -.587f, .809f, -0.5f,
        -.587f, .809f, -0.5f,
        0.0f, 0.0f, -1.0f
    };
    
    static const GLfloat color1[] = {0.828, 0.168, 0.168, 1.0};
    static const GLfloat color2[] = {0.695, 0.828, 0.168, 1.0};
    static const GLfloat color3[] = {0.168, 0.828, 0.433, 1.0};
    static const GLfloat color4[] = {0.168, 0.433, 0.828, 1.0};
    static const GLfloat color5[] = {0.695, 0.168, 0.828, 1.0};
    float s = .5;
    GLfloat color1e[] = {s*0.828, s*0.168, s*0.168, 1.0};
    GLfloat color2e[] = {s*0.695, s*0.828, s*0.168, 1.0};
    GLfloat color3e[] = {s*0.168, s*0.828, s*0.433, 1.0};
    GLfloat color4e[] = {s*0.168, s*0.433, s*0.828, 1.0};
    GLfloat color5e[] = {s*0.695, s*0.168, s*0.828, 1.0};
//    static const GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
//    static const GLfloat lightwhite[] = {0.2, 0.2, 0.2, 1.0};
    static const GLfloat black[] = {0.0, 0.0, 0.0, 1.0};

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white);
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, screenColor);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color1e);
    if(lit || litFace == 0)
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color1);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color1e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color1);
    glVertexPointer(3, GL_FLOAT, 0, tri1);
    glNormalPointer(GL_FLOAT, 0, tri1normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color2e);
    if(lit || litFace == 1)
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color2);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color2e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color2);
    glVertexPointer(3, GL_FLOAT, 0, tri2);
    glNormalPointer(GL_FLOAT, 0, tri2normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color3e);
    if(lit || litFace == 2)
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color3);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color3e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color3);
    glVertexPointer(3, GL_FLOAT, 0, tri3);
    glNormalPointer(GL_FLOAT, 0, tri3normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color4e);
    if(lit || litFace == 3)
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color4);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color4e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color4);
    glVertexPointer(3, GL_FLOAT, 0, tri4);
    glNormalPointer(GL_FLOAT, 0, tri4normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color5e);
    if(lit || litFace == 4)
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color5);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color5e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color5);
    glVertexPointer(3, GL_FLOAT, 0, tri5);
    glNormalPointer(GL_FLOAT, 0, tri5normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, black);
}

-(void)enterOrthographic{
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrthof(0, self.frame.size.width, self.frame.size.height, 0, -5, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

-(void)exitOrthographic{
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}

@end
