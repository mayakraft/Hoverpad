//
//  SmallModelView.m
//  Hoverpad
//
//  Created by Robby on 10/6/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "SmallModelView.h"
#import <OpenGL/gl.h>

#define ANGLE_CURVE_NUM_POINTS 16
#define R_r 1.1f

@interface SmallModelView (){
    GLfloat a[16];
    GLfloat pitchPoints[(1+ANGLE_CURVE_NUM_POINTS)*3];
    GLfloat rollPoints[(1+ANGLE_CURVE_NUM_POINTS)*3];
    GLfloat yawPoints[(1+ANGLE_CURVE_NUM_POINTS)*3];
    NSPoint mouseRotation;
    BOOL mouseRotationOn;
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

-(void)mouseMoved:(NSEvent *)theEvent{
    [super mouseMoved:theEvent];
}
-(void)mouseDragged:(NSEvent *)theEvent{
    [super mouseDragged:theEvent];
    if(mouseRotationOn){
        mouseRotation.x += [theEvent deltaX];
        mouseRotation.y -= [theEvent deltaY];
    }
    if(mouseRotation.x < 0) mouseRotation.x += 360;
    else if(mouseRotation.x > 360) mouseRotation.x -= 360;
    if(mouseRotation.y < 0) mouseRotation.y += 360;
    else if(mouseRotation.y > 360) mouseRotation.y -= 360;
    [self setNeedsDisplay:YES];
}
-(void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
    mouseRotationOn = true;
}
-(void)mouseUp:(NSEvent *)theEvent{
    [super mouseUp:theEvent];
    mouseRotationOn = false;
}

-(void) setupGL{
    for(int i = 0; i < 16; i++)
        a[i] = 0.0f;
    a[0] = a[5] = a[10] = a[15] = 1.0f;
    
    [self setPitchAngle:90];
    [self setRollAngle:90];
    [self setYawAngle:90];
    mouseRotation = NSMakePoint(45.0f, -25.0f);
    
    [self setWantsBestResolutionOpenGLSurface:YES];
    
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
    
    glRotatef(mouseRotation.y, 0, 1, 0);
    glRotatef(mouseRotation.x, 0, 0, 1);

    glEnableClientState(GL_VERTEX_ARRAY);
    
    glLineWidth(4);
    
    BOOL drawLinesBehind = false;
    
    if( ((int)(mouseRotation.x) % 360 > 130 && (int)(mouseRotation.x) % 360 < 320 ) )
        drawLinesBehind = true;
    if( ((int)(mouseRotation.y) % 360 > 90  && (int)(mouseRotation.y) % 360 < 270 ) )
        drawLinesBehind = !drawLinesBehind;
    
    
    if(drawLinesBehind)
        [self drawRangeLines];
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, black);
    [self drawBody];
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white10);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white80);
    [self drawTop];
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white20);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white50);
    [self drawScreen];

    if(!drawLinesBehind)
        [self drawRangeLines];
    


    glPopMatrix();
    
    glFlush();
}

-(void) setPitchAngle:(float)pitchAngle{
    _pitchAngle = pitchAngle;
    float increment = pitchAngle / 180.0 * M_PI / ANGLE_CURVE_NUM_POINTS;
    float startAngle = M_PI*.5 - pitchAngle / 180.0 * M_PI * .5;
    for(int i = 0; i <= ANGLE_CURVE_NUM_POINTS; i++){
        pitchPoints[i*3+0] = R_r * -sinf(startAngle + increment*i);
        pitchPoints[i*3+1] = 0.0f;
        pitchPoints[i*3+2] = R_r * cosf(startAngle + increment*i);
    }
    [self setNeedsDisplay:YES];
}
-(void) setRollAngle:(float)rollAngle{
    _rollAngle = rollAngle;
    float increment = rollAngle / 180.0 * M_PI / ANGLE_CURVE_NUM_POINTS;
    float startAngle = M_PI*.5 - rollAngle / 180.0 * M_PI * .5;
    for(int i = 0; i <= ANGLE_CURVE_NUM_POINTS; i++){
        rollPoints[i*3+0] = 0.0f;
        rollPoints[i*3+1] = R_r * sinf(startAngle + increment*i);
        rollPoints[i*3+2] = R_r * cosf(startAngle + increment*i);
    }
    [self setNeedsDisplay:YES];
}
-(void) setYawAngle:(float)yawAngle{
    _yawAngle = yawAngle;
    float increment = yawAngle / 180.0 * M_PI / ANGLE_CURVE_NUM_POINTS;
    float startAngle = M_PI*.5 - yawAngle / 180.0 * M_PI * .5;
    for(int i = 0; i <= ANGLE_CURVE_NUM_POINTS; i++){
        yawPoints[i*3+0] = R_r * -sinf(startAngle + increment*i);
        yawPoints[i*3+1] = R_r * cosf(startAngle + increment*i);
        yawPoints[i*3+2] = 0.0f;
    }
    [self setNeedsDisplay:YES];
}

-(void) setOrientation:(float *)q{
    a[0] = 1 - 2*q[1]*q[1] - 2*q[2]*q[2];   a[4] = 2*q[0]*q[1] - 2*q[2]*q[3];       a[8] = 2*q[0]*q[2] + 2*q[1]*q[3];
    a[1] = 2*q[0]*q[1] + 2*q[2]*q[3];       a[5] = 1 - 2*q[0]*q[0] - 2*q[2]*q[2];   a[9] = 2*q[1]*q[2] - 2*q[0]*q[3];
    a[2] = 2*q[0]*q[2] - 2*q[1]*q[3];       a[6] = 2*q[1]*q[2] + 2*q[0]*q[3];       a[10] = 1 - 2*q[0]*q[0] - 2*q[1]*q[1];
    a[3] = a[7] = a[11] = a[12] = a[13] = a[14] = 0.0f;
    a[15] = 1.0f;
}

-(void) drawRangeLines{
    static GLfloat black[] = {0.0, 0.0, 0.0, 1.0};
    static GLfloat red[] = {.9f, 0.0f, 0.0f, 1.0};
    static GLfloat green[] = {0.0f, .75f, 0.0f, 1.0f};
    static GLfloat blue[] = {0.0f, 0.0f, .9f, 1.0f};
    
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, black);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, black);

    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, red);
    glBegin(GL_LINE_STRIP);
    glNormal3f(-1,0,0);
    for(int i = 0; i <= ANGLE_CURVE_NUM_POINTS; i++){
        glVertex3f(pitchPoints[i*3+0],pitchPoints[i*3+1],pitchPoints[i*3+2]);
    }
    glEnd();

    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, green);
    glBegin(GL_LINE_STRIP);
    glNormal3f(0,1,0);
    for(int i = 0; i <= ANGLE_CURVE_NUM_POINTS; i++){
        glVertex3f(rollPoints[i*3+0],rollPoints[i*3+1],rollPoints[i*3+2]);
    }
    glEnd();

    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, blue);
    glBegin(GL_LINE_STRIP);
    glNormal3f(-1,0,0);
    for(int i = 0; i <= ANGLE_CURVE_NUM_POINTS; i++){
        glVertex3f(yawPoints[i*3+0],yawPoints[i*3+1],yawPoints[i*3+2]);
    }
    glEnd();

    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, black);
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
//    NSLog(@"REBUILDING PROJECTION %.1f, %.1f, ", _fieldOfView, _aspectRatio);
    
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
