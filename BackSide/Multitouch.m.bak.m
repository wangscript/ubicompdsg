//
//  Multitouch.m
//  WiTap
//
//  Created by Admin on 2008/12/3.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Multitouch.h"
#import "AppController.h"


@implementation Multitouch
@synthesize loc;

- (BOOL) isMultipleTouchEnabled {return YES;}  // 打開Multitouch支援

- (void) singleBack:(CGPoint)point{
	self.loc1 = point;
	[self setNeedsDisplay];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	printf("TouchesBegan ");
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	printf("Touch count:%d\n",count);
	int i;
	for (i=0 ; i<[self.loc count] ; i++){
		[self.loc objectAtIndex:i] = CGPointMake(999.0f, 999.0f);
		if (count > i) [self.loc objectAtIndex:i] = [[allTouches objectAtIndex:i] locationInView:self];
	}
	
	[(AppController*)[[UIApplication sharedApplication] delegate] transmitTouch:self.loc1 andType:1];	
	
	[self setNeedsDisplay];
}

// React to moved touches the same as to began
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	printf("TouchesMove ");
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	printf("Touch count:%d\n",count);
	
	if (count > 0) self.loc1 = [[allTouches objectAtIndex:0] locationInView:self];
	if (count > 1) self.loc2 = [[allTouches objectAtIndex:1] locationInView:self];
	if (count > 2) self.loc3 = [[allTouches objectAtIndex:2] locationInView:self];
	if (count > 3) self.loc4 = [[allTouches objectAtIndex:3] locationInView:self];
	if (count > 4) self.loc5 = [[allTouches objectAtIndex:4] locationInView:self];
	
	[(AppController*)[[UIApplication sharedApplication] delegate] transmitTouch:self.loc1 andType:2];
	
	[self setNeedsDisplay];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	printf("TouchesMove ");
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count] - 1;
	printf("Touch count:%d\n",count);
	self.loc1 = CGPointMake(999.0f, 999.0f);
	self.loc2 = CGPointMake(999.0f, 999.0f);
	self.loc3 = CGPointMake(999.0f, 999.0f);
	self.loc4 = CGPointMake(999.0f, 999.0f);
	self.loc5 = CGPointMake(999.0f, 999.0f);
	
	if (count > 0) self.loc1 = [[allTouches objectAtIndex:0] locationInView:self];
	if (count > 1) self.loc2 = [[allTouches objectAtIndex:1] locationInView:self];
	if (count > 2) self.loc3 = [[allTouches objectAtIndex:2] locationInView:self];
	if (count > 3) self.loc4 = [[allTouches objectAtIndex:3] locationInView:self];
	if (count > 4) self.loc5 = [[allTouches objectAtIndex:4] locationInView:self];
	
	[(AppController*)[[UIApplication sharedApplication] delegate] transmitTouch:self.loc1 andType:3];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)aRect {
	
	// Get the current context
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, aRect);
	
	// Set up the stroke and fill characteristics
	CGFloat red[4] = {0.75f, 0.25f, 0.25f, 1.0f};
	CGContextSetFillColor(context, red);
	
	CGRect p1box = CGRectMake(self.loc1.x, self.loc1.y, 0.0f, 0.0f);
	CGRect p2box = CGRectMake(self.loc2.x, self.loc2.y, 0.0f, 0.0f);
	CGRect p3box = CGRectMake(self.loc3.x, self.loc3.y, 0.0f, 0.0f);
	CGRect p4box = CGRectMake(self.loc4.x, self.loc4.y, 0.0f, 0.0f);
	CGRect p5box = CGRectMake(self.loc5.x, self.loc5.y, 0.0f, 0.0f);
	float offset = -25.0f;
	
	//CGMutablePathRef path;
	
	CGMutablePathRef path;
	
	// circle point 1
	if (self.loc1.x != 999){
		path = CGPathCreateMutable();
		CGPathAddEllipseInRect(path, NULL, CGRectInset(p1box, offset, offset));
		CGContextAddPath(context, path);
		CGContextFillPath(context);
		CFRelease(path);
	}
	// circle point 2
	if (self.loc2.x != 999){
		path = CGPathCreateMutable();
		CGPathAddEllipseInRect(path, NULL, CGRectInset(p2box, offset, offset));
		CGContextAddPath(context, path);
		CGContextFillPath(context);	
		CFRelease(path);
	}
	// circle point 3
	if (self.loc3.x != 999){
		path = CGPathCreateMutable();
		CGPathAddEllipseInRect(path, NULL, CGRectInset(p3box, offset, offset));
		CGContextAddPath(context, path);
		CGContextFillPath(context);	
		CFRelease(path);
	}
	// circle point 2
	if (self.loc4.x != 999){
		path = CGPathCreateMutable();
		CGPathAddEllipseInRect(path, NULL, CGRectInset(p4box, offset, offset));
		CGContextAddPath(context, path);
		CGContextFillPath(context);	
		CFRelease(path);
	}
	// circle point 2
	if (self.loc5.x != 999){
		path = CGPathCreateMutable();
		CGPathAddEllipseInRect(path, NULL, CGRectInset(p5box, offset, offset));
		CGContextAddPath(context, path);
		CGContextFillPath(context);	
		CFRelease(path);
	}
	
}


- (void)dealloc {
    [super dealloc];
}


@end
