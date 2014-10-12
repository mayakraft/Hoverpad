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

@interface ScreenView (){
    NSDate *animationStartTime;
    float y;
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
    static const GLfloat white[] = {1.0, 1.0, 1.0, 1.0};

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white);

    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color1);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color1);
    glVertexPointer(3, GL_FLOAT, 0, tri1);
    glNormalPointer(GL_FLOAT, 0, tri1normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color2);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color2);
    glVertexPointer(3, GL_FLOAT, 0, tri2);
    glNormalPointer(GL_FLOAT, 0, tri2normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color3);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color3);
    glVertexPointer(3, GL_FLOAT, 0, tri3);
    glNormalPointer(GL_FLOAT, 0, tri3normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color4);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color4);
    glVertexPointer(3, GL_FLOAT, 0, tri4);
    glNormalPointer(GL_FLOAT, 0, tri4normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, color5);
//    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, color5);
    glVertexPointer(3, GL_FLOAT, 0, tri5);
    glNormalPointer(GL_FLOAT, 0, tri5normal);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);

    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
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
-(void) beginAnimation{
    animationStartTime = [NSDate date];
}
-(void) update{
    float x = -[animationStartTime timeIntervalSinceNow]*4;
//    y = 10-(10/((x+.95)^2) * sin(2(x+.95));
    float s = .5;
    y = s-(s/powf((x+.95),2)) * sin(2*(x+.95));
    if(y < 0) y = 0;
}
-(void) draw{
    [self update];
    if(_isScreenTouched){
        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    }
    else{
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        glPushMatrix();
        glMultMatrixf(_deviceOrientation.m);
        
        glPushMatrix();
        glRotatef(-90, 0, 0, 1);
//        glTranslatef(0, 0, -5);
        if(animationStartTime)
            glTranslatef(0, 0, y);
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
    }
//    if(animationStartTime){
//        if(-[animationStartTime timeIntervalSinceNow] > 1.5){
//            animationStartTime = nil;
//        }
//    }
}

@end
