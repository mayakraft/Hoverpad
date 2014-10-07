//
//  SmallModelView.m
//  Hoverpad
//
//  Created by Robby on 10/6/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "SmallModelView.h"
#import <OpenGL/gl.h>

@interface SmallModelView (){
    GLfloat a[16];
}

@end

@implementation SmallModelView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        NSOpenGLContext *glcontext = [self openGLContext];
        [glcontext makeCurrentContext];
        [self rebuildProjectionMatrix];
        [self setupGL];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        NSOpenGLContext *glcontext = [self openGLContext];
        [glcontext makeCurrentContext];
        [self rebuildProjectionMatrix];
        [self setupGL];
    }
    return self;
}

-(void) setupGL{
    for(int i = 0; i < 16; i++)
        a[i] = 0.0f;
    a[0] = a[5] = a[10] = a[15] = 1.0f;
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_FRONT);
    glEnable(GL_DEPTH_TEST);
    GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat specular[] = {0.6, 0.6, 0.6, 1.0};
    GLfloat pos1[] = {0.0f, 0.0f, 10.0f, 1.0f};
    
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, white);
    glLightfv(GL_LIGHT0, GL_SPECULAR, specular);
    glLightfv(GL_LIGHT0, GL_POSITION, pos1);
    //    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 40);
    //    glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, .0005);
    GLfloat spot_direction[] = { 0.0, 0.0, -1.0 };
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, spot_direction);
    
    glShadeModel(GL_SMOOTH);
    glMateriali(GL_FRONT_AND_BACK, GL_SHININESS, 20);
}

- (void)drawRect:(NSRect)dirtyRect
{
    static GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    static GLfloat black[] = {0.0, 0.0, 0.0, 1.0};
    static GLfloat white10[] = {0.1f, 0.1f, 0.1f, 1.0};
    static GLfloat white20[] = {0.2f, 0.2f, 0.2f, 1.0};
    static GLfloat white50[] = {0.5f, 0.5f, 0.5f, 1.0f};
    static GLfloat white80[] = {0.8f, 0.8f, 0.8f, 1.0f};
    
    [super drawRect:dirtyRect];
    
    glClearColor(0.93f, 0.93f, 0.93f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glPushMatrix();
    glLoadIdentity();
    glTranslatef(0.0f, 0.0f, -7.0f);
    glRotatef(90, 0, 1, 0);
    glRotatef(-90, 1, 0, 0);
    glMultMatrixf(a);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, black);
    [self drawBody];
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white10);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white80);
    [self drawTop];
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white20);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white50);
//    if(_screenTouched){
//        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, white);
//        [self drawScreen];
//        glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, black);
//    }
//    else{
        [self drawScreen];
//    }
    
    
    glPopMatrix();
    
    glFlush();
}

-(void) setOrientation:(float *)q{
    a[0] = 1 - 2*q[1]*q[1] - 2*q[2]*q[2];   a[4] = 2*q[0]*q[1] - 2*q[2]*q[3];       a[8] = 2*q[0]*q[2] + 2*q[1]*q[3];
    a[1] = 2*q[0]*q[1] + 2*q[2]*q[3];       a[5] = 1 - 2*q[0]*q[0] - 2*q[2]*q[2];   a[9] = 2*q[1]*q[2] - 2*q[0]*q[3];
    a[2] = 2*q[0]*q[2] - 2*q[1]*q[3];       a[6] = 2*q[1]*q[2] + 2*q[0]*q[3];       a[10] = 1 - 2*q[0]*q[0] - 2*q[1]*q[1];
    a[3] = a[7] = a[11] = a[12] = a[13] = a[14] = 0.0f;
    a[15] = 1.0f;
}

-(void) drawTop{
    // top
    glBegin(GL_TRIANGLES);
    glNormal3f(0,0,1);
    glVertex3f(.5,1,.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(-.5,1,.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(.5,1,.05);
    glVertex3f(.5,-1,.05);
    glEnd();
    
}

-(void) drawScreen{
    // top
    glBegin(GL_TRIANGLES);
    glNormal3f(0,0,1);
    glVertex3f(.45,.775,.055);
    glVertex3f(-.45,-.775,.055);
    glVertex3f(-.45,.775,.055);
    glVertex3f(-.45,-.775,.055);
    glVertex3f(.45,.775,.055);
    glVertex3f(.45,-.775,.055);
    glEnd();
    
}


-(void) drawBody{
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    // bottom
    glColor4f(.7, .7, .7, .7);
    glBegin(GL_TRIANGLES);
    glNormal3f(0,0,-1);
    glVertex3f(.5,1,-.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(.5,-1,-.05);
    glVertex3f(.5,1,-.05);
    glEnd();
    
    // side top or bottom
    glBegin(GL_TRIANGLES);
    glNormal3f(0,-1,0);
    glVertex3f(.5,-1,.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(.5,-1,.05);
    glVertex3f(.5,-1,-.05);
    glEnd();
    
    // side top or bottom
    glBegin(GL_TRIANGLES);
    glNormal3f(0,1,0);
    glVertex3f(-.5,1,.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(.5,1,.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(.5,1,-.05);
    glVertex3f(.5,1,.05);
    glEnd();
    
    
    // side left or right
    glBegin(GL_TRIANGLES);
    glNormal3f(-1,0,0);
    glVertex3f(-.5,1,.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(-.5,1,.05);
    glEnd();
    
    // side left or right
    glBegin(GL_TRIANGLES);
    glNormal3f(1,0,0);
    glVertex3f(.5,1,.05);
    glVertex3f(.5,-1,-.05);
    glVertex3f(.5,-1,.05);
    glVertex3f(.5,-1,-.05);
    glVertex3f(.5,1,.05);
    glVertex3f(.5,1,-.05);
    glEnd();
}

-(void) rebuildProjectionMatrix{
    static float Z_NEAR = 0.01f;
    static float Z_FAR = 100.0f;
    static float _fieldOfView = 30;
    float _aspectRatio = (float)[[NSScreen mainScreen] frame].size.width / (float)[[NSScreen mainScreen] frame].size.height;
    NSLog(@"REBUILDING PROJECTION %.1f, %.1f, ", _fieldOfView, _aspectRatio);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    GLfloat frustum = Z_NEAR * tanf(_fieldOfView*0.00872664625997);  // pi / 180 / 2
    glFrustum(-frustum, frustum, -frustum/_aspectRatio, frustum/_aspectRatio, Z_NEAR, Z_FAR);
    glViewport(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height);
    glMatrixMode(GL_MODELVIEW);
}

- (void)reshape{   // window scrolled, moved or resized
    //	NSRect baseRect = [self convertRectToBase:[self bounds]];
    //	w = baseRect.size.width;
    //	h = baseRect.size.height;
    [[self openGLContext] update];
    [[self window] setAcceptsMouseMovedEvents:YES];
}

@end
