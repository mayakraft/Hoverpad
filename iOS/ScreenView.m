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


typedef enum : NSUInteger {
    noAnimation,
    buttonSearching,
    buttonRise,
    buttonConnected,
    buttonFall,
} buttonAnimation;

@interface ScreenView (){
    NSDate *animationStateStart;
    float y;
    buttonAnimation animation;
    GLfloat groundColor[4];
    int litFace;
}

@end

@implementation ScreenView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(id)initWithFrame:(CGRect)frame context:(EAGLContext *)context{
    self = [super initWithFrame:frame context:context];
    if(self){
        [self initOpenGL];
    }
    return self;
}

-(void)initOpenGL{
    _aspectRatio = self.frame.size.width/self.frame.size.height;
//    _fieldOfView = 45 + 45 * atanf(_aspectRatio); // hell ya
    _fieldOfView = 40;
    [self rebuildProjectionMatrix];
    
    static GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    static GLfloat black[] = {0.0, 0.0, 0.0, 1.0};
    static GLfloat white10[] = {0.1f, 0.1f, 0.1f, 1.0};
    static GLfloat white20[] = {0.2f, 0.2f, 0.2f, 1.0};
    static GLfloat white50[] = {0.5f, 0.5f, 0.5f, 1.0f};
    static GLfloat white80[] = {0.8f, 0.8f, 0.8f, 1.0f};
    
    groundColor[0] = groundColor[1] = groundColor[2] = 0.0f;
    groundColor[3] = 1.0f;
    
//    GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat specular[] = {0.6, 0.6, 0.6, 1.0};
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

-(void) setState:(NSUInteger)state{
    if(state == 1){
        animation = buttonSearching;
        animationStateStart = [NSDate date];
    }
    if(state == 3){
        animation = buttonRise;
        animationStateStart = [NSDate date];
    }
    if(state == 4){
        if(_state == 2)
            animation = noAnimation;
        else{
            animation = buttonFall;
            animationStateStart = [NSDate date];
        }
    }
    _state = state;
}

-(void) update{
    if(animation){
        if(animation == buttonSearching) {
            litFace = ((int)(-[animationStateStart timeIntervalSinceNow]*10))%5;
        }
        if(animation == buttonRise || animation == buttonFall){
            float x = -[animationStateStart timeIntervalSinceNow]*4;
//            y = 10-(10/((x+.95)^2) * sin(2(x+.95));
            float s = .5;
            y = s-(s/powf((x+.95),2)) * sin(2*(x+.95));
            if(y < 0) y = 0;
        }
        float darkness;
        if(animation == buttonRise)
            darkness = -[animationStateStart timeIntervalSinceNow]*2;
        else //if(animation == buttonFall)
            darkness = 1.0+[animationStateStart timeIntervalSinceNow]*4;
        
        if(darkness > 1.0) darkness = 1.0;
        if(darkness < 0.0) darkness = 0.0;
        groundColor[0] = groundColor[1] = groundColor[2] = darkness;
    }
}

-(void) draw{
    [self update];
//    if(_isScreenTouched){
//        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
//        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
//    }
    if(1){
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        glPushMatrix();
        glMultMatrixf(_deviceOrientation.m);
        
        glPushMatrix();
        glRotatef(-90, 0, 0, 1);
//        glTranslatef(0, 0, -5);
        if(groundColor[0] != 0.0)
            [self glDrawTable];
        
            glPushMatrix();
            if(animation == buttonRise)
                glTranslatef(0, 0, y);
            if(animation == buttonFall)
                glTranslatef(0, 0, .5-y);
        
//        if(_isButtonTouched)
//            glColor4f(1.0f, 0.0f, 1.0f, 1.0f);
//        else if(_state == 3)
//            glColor4f(0.1f, 0.1f, 0.1f, 1.0f);
//        else if(animationStartTime)
//            glColor4f(arc4random()%100/100.0, arc4random()%100/100.0, arc4random()%100/100.0, 1.0f);
//        else
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
        [self glDrawPentagonTriangles];
        glPopMatrix();
        glPopMatrix();
        glPopMatrix();
    }
//    if(animationStartTime){
//        if(-[animationStartTime timeIntervalSinceNow] > 1.5){
//            animationStartTime = nil;
//        }
//    }
}

-(void) glDrawTable{
    float s = 1.3;
    static const GLfloat centerVertices[] = {
        0.0f, 0.0f, -0.1f,
        0.0f, 1.0f, -0.1f,
        .951f, .309f, -0.1f,
        .5878, -.809, -0.1f,
        -.5878, -.809, -0.1f,
        -.951f, .309f, -0.1f,
        0.0f, 1.0f, -0.1f
    };
    static const GLfloat centerNormals[] = {
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f
    };
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
//    GLfloat tableVertices[] = {
//        0.0f, 1.0f, -0.1f,
//        0.0f, s*1.0f, -0.1f,
//        .951f, .309f, -0.1f,
//        s*.951f, s*.309f, -0.1f,
//        .5878, -.809, -0.1f,
//        s*.5878, s*-.809, -0.1f,
//        -.5878, -.809, -0.1f,
//        s*-.5878, s*-.809, -0.1f,
//        -.951f, .309f, -0.1f,
//        s*-.951f, s*.309f, -0.1f,
//        0.0f, 1.0f, -0.1f,
//        0.0f, s*1.0f, -0.1f
//    };
    
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
    static const GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    static const GLfloat black[] = {0.0, 0.0, 0.0, 1.0};
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, black);
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, groundColor);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color1);
    glVertexPointer(3, GL_FLOAT, 0, tableVertices);
    glNormalPointer(GL_FLOAT, 0, tableNormals);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 12);
    
//    glVertexPointer(3, GL_FLOAT, 0, centerVertices);
//    glNormalPointer(GL_FLOAT, 0, centerNormals);
//    glDrawArrays(GL_TRIANGLE_FAN, 0, 7);

    
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
}

-(void) glDrawPentagonTriangles{
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
    static const GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    static const GLfloat lightwhite[] = {0.2, 0.2, 0.2, 1.0};
    static const GLfloat black[] = {0.0, 0.0, 0.0, 1.0};

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white);
    
    if(_isScreenTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, white);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, black);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color1e);
    if(animation==buttonRise || animation==buttonConnected || (animation==buttonSearching && litFace==0) )
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color1);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color1e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color1);
    glVertexPointer(3, GL_FLOAT, 0, tri1);
    glNormalPointer(GL_FLOAT, 0, tri1normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color2e);
    if(animation==buttonRise || animation==buttonConnected || (animation==buttonSearching && litFace==1) )
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color2);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color2e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color2);
    glVertexPointer(3, GL_FLOAT, 0, tri2);
    glNormalPointer(GL_FLOAT, 0, tri2normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color3e);
    if(animation==buttonRise || animation==buttonConnected || (animation==buttonSearching && litFace==2) )
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color3);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color3e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color3);
    glVertexPointer(3, GL_FLOAT, 0, tri3);
    glNormalPointer(GL_FLOAT, 0, tri3normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color4e);
    if(animation==buttonRise || animation==buttonConnected || (animation==buttonSearching && litFace==3) )
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color4);
    else
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color4e);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color4);
    glVertexPointer(3, GL_FLOAT, 0, tri4);
    glNormalPointer(GL_FLOAT, 0, tri4normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    if(_isButtonTouched)
        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, color5e);
    if(animation==buttonRise || animation==buttonConnected || (animation==buttonSearching && litFace==4) )
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
//-(void) glDrawPentagonTriangles{
//    static const GLfloat tri1[] = {
//        0.0f, 0.0f,
//        0.0f, 1.0f,
//        .951f, .309f };
//    static const GLfloat tri2[] = {
//        0.0f, 0.0f,
//        .951f, .309f,
//        .5878, -.809 };
//    static const GLfloat tri3[] = {
//        0.0f, 0.0f,
//        .5878, -.809,
//        -.5878, -.809
//    };
//    static const GLfloat tri4[] = {
//        0.0f, 0.0f,
//        -.5878, -.809,
//        -.951f, .309f
//    };
//    static const GLfloat tri5[] = {
//        0.0f, 0.0f,
//        -.951f, .309f,
//        0.0f, 1.0f
//    };
//    
//    glEnableClientState(GL_VERTEX_ARRAY);
//    
//    glColor4ub(212, 43, 43, 255);
//    glVertexPointer(2, GL_FLOAT, 0, tri1);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//    
//    glColor4ub(178, 212, 43, 255);
//    glVertexPointer(2, GL_FLOAT, 0, tri2);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//    
//    glColor4ub(43, 212, 111, 255);
//    glVertexPointer(2, GL_FLOAT, 0, tri3);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//    
//    glColor4ub(43, 111, 212, 255);
//    glVertexPointer(2, GL_FLOAT, 0, tri4);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//    
//    glColor4ub(178, 43, 212, 255);
//    glVertexPointer(2, GL_FLOAT, 0, tri5);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//    
//    glDisableClientState(GL_VERTEX_ARRAY);
//}

//-(void) glDrawPentagon{
//    static const GLfloat pentFan[] = {
//        0.0f, 0.0f,
//        0.0f, 1.0f,
//        .951f, .309f,
//        .5878, -.809,
//        -.5878, -.809,
//        -.951f, .309f,
//        0.0f, 1.0f
//    };
//    glEnableClientState(GL_VERTEX_ARRAY);
//    glVertexPointer(2, GL_FLOAT, 0, pentFan);
//    glDrawArrays(GL_TRIANGLE_FAN, 0, 7);
//    glDisableClientState(GL_VERTEX_ARRAY);
//}

@end
