//
//  View.m
//  BluetoothHost
//
//  Created by Robby on 4/9/14.
//  Copyright (c) 2014 Robby Kraft. All rights reserved.
//

#import "View.h"
#import <OpenGL/gl.h>

#import <GLKit/GLKit.h>

@interface View (){
    GLfloat attitude[16];
    GLfloat a[16];
    GLKQuaternion orientation;
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
        [self loadGL];
        [self rebuildProjectionMatrix];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        NSOpenGLContext *glcontext = [self openGLContext];
        [glcontext makeCurrentContext];
        [self loadGL];
        [self rebuildProjectionMatrix];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    glDisable(GL_LIGHTING);
    glDisable(GL_CULL_FACE);

    glClearColor(.2, .2, .2, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glPushMatrix();
    glLoadIdentity();

    glTranslatef(0.0f, 0.0f, -10.0f);
    glRotatef(90, 1, 0, 0);
    
    
    glMultMatrixf(GLKMatrix4MakeWithQuaternion(orientation).m);
    
    glEnableClientState(GL_VERTEX_ARRAY);
  
    [self drawQuad];

    glDisableClientState(GL_VERTEX_ARRAY);

    
    glPopMatrix();
    
    glFlush();
}

-(void) encodedOrientation:(NSData*) receivedData{
    char *data = (char*)[receivedData bytes];
    NSLog(@"R: %@",receivedData);
    char x, y, z, w;
    x = data[0];
    y = data[1];
    z = data[2];
    w = data[3];
    NSLog(@"%d (%d, %d, %d) ",w, x, y, z);
//    NSLog(@"%d (%d, %d, %d) ", bytes[3],bytes[0], bytes[1], bytes[2]);

    float qx, qy, qz, qw;
    qx = x / 128.0f;
    qy = y / 128.0f;
    qz = z / 128.0f;
    qw = w / 128.0f;
    orientation = GLKQuaternionMake(qx, qy, qz, qw);
    NSLog(@"%f (%f, %f, %f)",qw, qx, qy, qz);
    
    a[0] = 1 - 2*qy*qy - 2*qz*qz;   a[1] = 2*qx*qy - 2*qz*qw;       a[2] = 2*qx*qz + 2*qy*qw;
    a[4] = 2*qx*qy + 2*qz*qw;       a[5] = 1 - 2*qx*qx - 2*qz*qz;   a[6] = 2*qy*qz - 2*qx*qw;
    a[8] = 2*qx*qz - 2*qy*qw;       a[9] = 2*qy*qz + 2*qx*qw;       a[10] = 1 - 2*qx*qx - 2*qy*qy;
    
    a[3] = a[7] = a[11] = a[12] = a[13] = a[14] = 0.0f;
    a[15] = 1.0f;
}

-(void) updateAttitude:(NSString*)string{
//    3-0.849-0.142+0.508
    NSString *index = [string substringToIndex:1];
    NSString *one = [string substringWithRange:NSMakeRange(1, 6)];
    NSString *two = [string substringWithRange:NSMakeRange(7, 6)];
    NSString *three = [string substringWithRange:NSMakeRange(13, 6)];
    one = [one stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"+"]];
    two = [two stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"+"]];
    three = [three stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"+"]];
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    if([index isEqualToString:@"1"]){
        NSNumber *n1 = [f numberFromString:one];
        NSNumber *n2 = [f numberFromString:two];
        NSNumber *n3 = [f numberFromString:three];
        attitude[0] = [n1 floatValue];
        attitude[4] = [n2 floatValue];
        attitude[8] = [n3 floatValue];
    }
    if([index isEqualToString:@"2"]){
        NSNumber *n1 = [f numberFromString:one];
        NSNumber *n2 = [f numberFromString:two];
        NSNumber *n3 = [f numberFromString:three];
        attitude[1] = [n1 floatValue];
        attitude[5] = [n2 floatValue];
        attitude[9] = [n3 floatValue];
    }
    if([index isEqualToString:@"3"]){
        NSNumber *n1 = [f numberFromString:one];
        NSNumber *n2 = [f numberFromString:two];
        NSNumber *n3 = [f numberFromString:three];
        attitude[2] = [n1 floatValue];
        attitude[6] = [n2 floatValue];
        attitude[10] = [n3 floatValue];
    }
//    NSLog(@"\n%.3f %.3f %.3f, %.3f\n%.3f %.3f %.3f, %.3f\n%.3f %.3f %.3f, %.3f\n%.3f %.3f %.3f, %.3f\n",
//          attitude[0], attitude[1], attitude[2], attitude[3],
//          attitude[4], attitude[5], attitude[6], attitude[7],
//          attitude[8], attitude[9], attitude[10], attitude[11],
//          attitude[12], attitude[13], attitude[14], attitude[15]);
}

-(void) loadGL{
    for(int i = 0; i < 16; i++)
        a[i] = 0.0f;
    a[0] = a[5] = a[10] = a[15] = 1.0f;
}


-(void) drawQuad{
    glColor4f(1, 1, 1, 1);
    glBegin(GL_TRIANGLES);
    glNormal3f(0,0,1);
    glTexCoord2f(1,1);  glVertex3f(1,1,0);
    glTexCoord2f(0,1);  glVertex3f(-1,1,0);
    glTexCoord2f(0,0);  glVertex3f(-1,-1,0);
    glTexCoord2f(0,0);  glVertex3f(-1,-1,0);
    glTexCoord2f(1,0);  glVertex3f(1,-1,0);
    glTexCoord2f(1,1);  glVertex3f(1,1,0);
    glEnd();
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
