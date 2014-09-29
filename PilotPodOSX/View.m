//
//  View.m
//  BluetoothHost
//
//  Created by Robby on 4/9/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "View.h"
#import <OpenGL/gl.h>

@interface View (){
    GLfloat a[16];
}

@end

@implementation View

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        NSOpenGLContext *glcontext = [self openGLContext];
        [glcontext makeCurrentContext];
        [self setupGL];
        [self rebuildProjectionMatrix];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        NSOpenGLContext *glcontext = [self openGLContext];
        [glcontext makeCurrentContext];
        [self setupGL];
        [self rebuildProjectionMatrix];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    glClearColor(.2, .2, .2, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glPushMatrix();
    glLoadIdentity();

    glTranslatef(0.0f, 0.0f, -7.0f);
    glRotatef(-90, 1, 0, 0);
    glMultMatrixf(a);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    [self drawQuad];
    glDisableClientState(GL_VERTEX_ARRAY);

    glPopMatrix();
    
    glFlush();
}

-(void) spotlighting{
    glEnable(GL_DEPTH_TEST);
    GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat pos1[] = {0.0f, 0.0f, -50.0f, 1.0f};
    glLightfv(GL_LIGHT0, GL_DIFFUSE, white);
    glLightfv(GL_LIGHT0, GL_POSITION, pos1);
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
    glShadeModel(GL_SMOOTH);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
//    static GLfloat lightWhite[4] = {.60f, .60f, .60f, 1.0f};
    static GLfloat lightWhite[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, lightWhite);
}


-(void) setOrientation:(float *)q{
    a[0] = 1 - 2*q[1]*q[1] - 2*q[2]*q[2];   a[4] = 2*q[0]*q[1] - 2*q[2]*q[3];       a[8] = 2*q[0]*q[2] + 2*q[1]*q[3];
    a[1] = 2*q[0]*q[1] + 2*q[2]*q[3];       a[5] = 1 - 2*q[0]*q[0] - 2*q[2]*q[2];   a[9] = 2*q[1]*q[2] - 2*q[0]*q[3];
    a[2] = 2*q[0]*q[2] - 2*q[1]*q[3];       a[6] = 2*q[1]*q[2] + 2*q[0]*q[3];       a[10] = 1 - 2*q[0]*q[0] - 2*q[1]*q[1];
    a[3] = a[7] = a[11] = a[12] = a[13] = a[14] = 0.0f;
    a[15] = 1.0f;
}

-(void) setupGL{
    for(int i = 0; i < 16; i++)
        a[i] = 0.0f;
    a[0] = a[5] = a[10] = a[15] = 1.0f;
    
    glEnable(GL_CULL_FACE);
    [self spotlighting];
}


-(void) drawQuad{
    glColor4f(.3, .3, .3, .3);
    // top
    glBegin(GL_TRIANGLES);
    glNormal3f(0,0,-1);
    glVertex3f(.5,1,.05);
    glVertex3f(-.5,1,.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(.5,-1,.05);
    glVertex3f(.5,1,.05);
    glEnd();

    // bottom
    glColor4f(.7, .7, .7, .7);
    glBegin(GL_TRIANGLES);
    glNormal3f(0,0,1);
    glVertex3f(.5,1,-.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(.5,1,-.05);
    glVertex3f(.5,-1,-.05);
    glEnd();
    
    // side top or bottom
    glBegin(GL_TRIANGLES);
    glNormal3f(0,1,0);
    glVertex3f(.5,-1,.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(.5,-1,-.05);
    glVertex3f(.5,-1,.05);
    glEnd();

    // side top or bottom
    glBegin(GL_TRIANGLES);
    glNormal3f(0,-1,0);
    glVertex3f(-.5,1,.05);
    glVertex3f(.5,1,.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(-.5,1,-.05);
    glVertex3f(.5,1,.05);
    glVertex3f(.5,1,-.05);
    glEnd();
    
    
    // side left or right
    glBegin(GL_TRIANGLES);
    glNormal3f(1,0,0);
    glVertex3f(-.5,1,.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,-1,.05);
    glVertex3f(-.5,-1,-.05);
    glVertex3f(-.5,1,.05);
    glVertex3f(-.5,1,-.05);
    glEnd();
    
    // side left or right
    glBegin(GL_TRIANGLES);
    glNormal3f(-1,0,0);
    glVertex3f(.5,1,.05);
    glVertex3f(.5,-1,.05);
    glVertex3f(.5,-1,-.05);
    glVertex3f(.5,-1,-.05);
    glVertex3f(.5,1,-.05);
    glVertex3f(.5,1,.05);
    glEnd();

    
//    glTexCoord2f(1,1);  glVertex3f(1,1,0);
//    glTexCoord2f(0,1);  glVertex3f(-1,1,0);
//    glTexCoord2f(0,0);  glVertex3f(-1,-1,0);
//    glTexCoord2f(0,0);  glVertex3f(-1,-1,0);
//    glTexCoord2f(1,0);  glVertex3f(1,-1,0);
//    glTexCoord2f(1,1);  glVertex3f(1,1,0);
//    glEnd();
//    glBindTexture(GL_TEXTURE_2D, 0);
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
