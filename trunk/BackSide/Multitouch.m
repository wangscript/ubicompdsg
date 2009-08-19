
#import "Multitouch.h"
#import "AppController.h"
#import <math.h>

#define DRAG_INITIAL_LIMIT		50
#define DRAG_MOVING_LIMIT		200
#define DRAG_CANCEL_FLIP_LIMIT  20
#define FLIP_INITIAL_LIMIT		50
#define CANCEL_LENGTH           20
#define CANCEL_DRAG_LIMIT       50
#define CANCEL_FLIP_LIMIT       80

#define PUSH_INITIAL_PERIOD		0.5
#define PUSH_INITIAL_WAIT_TIME	0.5
#define PUSH_PERIOD_TIME		0.2

@implementation TouchPoint

@synthesize _point;
@synthesize _touch;

BOOL debug = NO;

- (TouchPoint*) initWithTouch: (UITouch*)t andPoint: (CGPoint)p
{
	if (self) {
		_touch = t;
		_point = p;
	}
	return self;
}

@end

@implementation Multitouch

@synthesize frontLoc, backLoc;
@synthesize place;

- (BOOL) isMultipleTouchEnabled { return YES; } // 打開Multitouch支援

- (void) init {
	
	self.frontLoc = [NSMutableArray arrayWithCapacity:5]; // memory space
	self.backLoc  = [NSMutableArray arrayWithCapacity:5]; 


	
	CGPoint point;
	self.place = [[TouchPoint alloc] initWithTouch:nil andPoint:point];
	int i;
	for ( i = 0 ; i < 5 ; i++ ) {
		[self.frontLoc addObject:self.place];
		[self.backLoc addObject:self.place];
	}
	
	for ( i = 0 ; i < 10 ; i++ ) {
		used[i] = NO;
	}
}    

- (int) findEmpty:(BOOL) front{
	int index;
	if(front){
		for(index = 0 ; index < 5 ; index++){
			if(!used[index]){
				used[index] = TRUE;
				return index;
			}
		}
		return 10; // front side full
	}
	return 5;
}

- (int) touchBegan:(UITouch*)touch andPoint:(CGPoint)point andFront:(bool)front andNum:(int)num{	
	int index;
	if (front) {
		index = [self findEmpty:front];
		[self.frontLoc replaceObjectAtIndex: index
								 withObject: [[TouchPoint alloc] initWithTouch: touch
																	  andPoint: point]];
		used[index] = TRUE;
		// ----------------------------------------

		// ----------------------------------------
	}
	 
	return index;
}  

- (int) touchMove:(UITouch*)touch andPoint:(CGPoint)point andFront:(bool)front andNum:(int)num{
	
	int i;
	TouchPoint* tp1;

	if(front){ // compare memory location
		for(i = 0 ; i < 5 ; i++){
			tp1 = [self.frontLoc objectAtIndex:i];
			if(tp1._touch == touch){
				tp1._point = point;
				break;
			}
		}
	}
	 
	return i;
} 

- (int) touchEnd:(UITouch*)touch andPoint:(CGPoint)point andFront:(bool)front andNum:(int)num {
	
	int i;
	TouchPoint * tempPtr;
	if(front){
		for(i = 0 ; i < 5 ; i++){
			tempPtr = [self.frontLoc objectAtIndex:i];
			if(tempPtr._touch == touch){
				used[i] = FALSE;
				break;
			}
		}
	}

	return i;
}  

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
	if(debug) printf("TouchesBegan ");
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	int i;
	int num;
	for ( i = 0 ; i < count ; i++) {
		// add a new touch point into multitouch.loc
		num = [self touchBegan:[allTouches objectAtIndex:i]
					  andPoint:[[allTouches objectAtIndex:i] locationInView:self]
					  andFront:YES
					  andNum:11 // useless 
			   ];
		
		_SameTouchIdx[i] = num;
		
		[(AppController*)[[UIApplication sharedApplication] delegate]
		 transmitTouch:[[allTouches objectAtIndex:i] locationInView:self] // CGPoint
		 andNum:num  // array index 
		 andType:1   // began/moved/ended
		];
	}
	if(count > 1){
		_SameTouchCount = count;
		[(AppController*)[[UIApplication sharedApplication] delegate]
		 transmitTouchAtSameTime: _SameTouchIdx andCount: _SameTouchCount];
	}
	[self setNeedsDisplay]; // draw
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{
	if(debug) printf("TouchesMove ");
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	int i, index;
	for (i=0 ; i<count ; i++) {
		index = [self touchMove:[allTouches objectAtIndex:i]
					   andPoint:[[allTouches objectAtIndex:i] locationInView:self]
					   andFront:YES
						 andNum:11 ];
		
		[(AppController*)[[UIApplication sharedApplication] delegate]
		 transmitTouch: [[allTouches objectAtIndex:i] locationInView: self]
		        andNum: index
			   andType: 2
		]; // send
	}
	
	[self setNeedsDisplay]; // draw
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if(debug) printf("TouchesEnd ");
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	int i, index;
	for (i=0 ; i<count ; i++) {
		index = [self touchEnd:[allTouches objectAtIndex:i]
				  andPoint:[[allTouches objectAtIndex:i] locationInView:self]
				  andFront:YES
				  andNum: 11
			];
		
		[(AppController*)[[UIApplication sharedApplication] delegate]
		 transmitTouch:[[allTouches objectAtIndex:i] locationInView:self]
		andNum:index
		andType:3
		];
	 }
	
	[self setNeedsDisplay];
}
// more than 5 touch points -> remove all touch points
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	if(debug) printf("TouchesCancelled ");
	int i;
	CGPoint fack;
	for( i = 0 ; i < 5 ; i++){
		if(used[i]){ 
			used[i] = FALSE;
			[(AppController*)[[UIApplication sharedApplication] delegate]
			 transmitTouch:fack
			 andNum:i
			 andType:3
			 ];
		}
	}

	[self setNeedsDisplay];
} 

- (void) drawRect:(CGRect)aRect {
	
	if(debug) printf("drawRect\n");//debug
	
	// Get the current context
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, aRect);
	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
	CGContextFillRect(context, aRect); 
	// Set up the stroke and fill characteristics
	//CGFloat red[4] = {0.75f, 0.25f, 0.25f, 1.0f};
	
	CGMutablePathRef path;
	
	//[self onTimer];
	
	int i;
	for(i=0 ; i<10 ; i++){
		TouchPoint* tp = nil;
		if(used[i]){
			if (i < 5) {
				tp = [self.frontLoc objectAtIndex:i];
				CGContextSetRGBFillColor(context, 1, 0, 0, 1); // (context,R,G,B,alpha)
			}
			else {
				tp = [self.backLoc objectAtIndex:i-5];
				CGContextSetRGBFillColor(context, 0, 0, 1, 1);
			}
		}
		if(tp != nil){
			CGRect pbox = CGRectMake(tp._point.x, tp._point.y, 0.0f, 0.0f);
			path = CGPathCreateMutable();
			float offset = -5.0f;
			CGPathAddEllipseInRect(path, NULL, CGRectInset(pbox, offset, offset)); // draw a small point
			CGContextAddPath(context, path);
			CGContextFillPath(context);
			
			offset = -25.0f;
			CGPathAddEllipseInRect(path, NULL, CGRectInset(pbox, offset, offset)); // draw a big gray point
			CGContextSetRGBFillColor(context, 1, 1, 1, 0.5);
			CGContextAddPath(context, path);
			CGContextFillPath(context);
			
			CFRelease(path); 
		}
	}
	 
	
}

//-----------------------



- (void) dealloc {
    [super dealloc];
}

@end
