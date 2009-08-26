//
//  EAGLView.mm
//  For Double side
//
BOOL strtDebug = YES;

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"
#import "main.h"
#import "template.h"
#import "templateAppDelegate.h"

#define DRAG_INITIAL_LIMIT		50
#define DRAG_MOVING_LIMIT		200
#define DRAG_CANCEL_FLIP_LIMIT  20
#define FLIP_INITIAL_LIMIT		100
#define CANCEL_LENGTH           20
#define CANCEL_DRAG_LIMIT       50
#define CANCEL_FLIP_LIMIT       120
#define STRETCH_INITIAL_LIMIT   100
#define STRETCH_MOVE_THRESOULD  100

#define PUSH_INITIAL_PERIOD		0.5
#define PUSH_INITIAL_WAIT_TIME	0.2
#define PUSH_PERIOD_TIME		0.1

#define Camera_Moved_Mode       0
#define Object_Moved_Mode       1
#define Object_Scale_Mode       2

//---------------------------------------------------------
#define ROTATE_WAIT             0
#define ROTATE_UP               1
#define ROTATE_RIGHT            2
#define ROTATE_DOWN             3
#define ROTATE_LEFT				4
#define ROTATE_X				5
//---------------------------------------------------------

#define INTOBJ(v) [NSNumber numberWithInteger: v]

#pragma mark -

extern NSString *FILENAME;
extern char taskState;
extern bool positionRegenerated;


extern NSMutableArray	*gestureSequence;
extern bool				fingersOnFront;
extern bool				fingersOnBack;
extern SIO2object       *selection;

extern unsigned char	tap_select;  // For GRAB Gesture
extern bool             isAllTaskFinished;
extern bool             isReadyToLog;

extern vec2				*selectionPosition;



//
extern int movement[100];
extern int movementOne;



//for flip
extern BOOL isRotateEnded;
extern BOOL oldIsRotateEnded;

extern GLfloat matrixrotate[16];


@implementation TouchPoint

@synthesize _point;
@synthesize _touch;

- (TouchPoint*) initWithTouch:(UITouch*)t andPoint:(CGPoint)p  
{
	if (self) {
		_touch = t;
		_point = p;
	}
	return self;
}

@end

// A class extension to declare private methods
@interface EAGLView ()

BOOL isDebug = YES;

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize place;
@synthesize frontLoc;
@synthesize backLoc;
@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;

#pragma mark Original functions of EAGLView.mm from sio2
// ====== Original functions of EAGLView.mm from sio2 START ======

+ (Class)layerClass {
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
    
	if(isDebug) printf("@Initiating the glView object!!----------\n");
	if ((self = [super initWithCoder:coder])) {
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
		   [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}
		
		animationInterval = 1.0 / 60.0;
		
	// Algmented initiation part for Both-Side touch: -------------------
		int i;
		self.frontLoc = [NSMutableArray arrayWithCapacity:5];
		self.backLoc  = [NSMutableArray arrayWithCapacity:5];	
		
		CGPoint point;
		self.place = [[TouchPoint alloc] initWithTouch:nil andPoint:point];
		
		for( i = 0 ; i < 5 ; i++ ){
			[self.frontLoc addObject:self.place];
			[self.backLoc addObject:self.place];
		}
		
		for (i=0; i<10; i++) {
			isUsed[i] = FALSE;
		}
		
		newestDragFrontIdx[0] = 5;
		newestDragFrontIdx[1] = 5;
		newestDragBackIdx[0]  = 5;
		newestDragBackIdx[1]  = 5;
		newestFlipFrontIdx    = 5;
		newestFlipBackIdx     = 5;
		
		dragState  = NO;
		flipState  = NO;
		isFlipX    = NO;
		isFlipY    = NO;
		strtState  = NO;
		strtExpand = NO;
		isStrtHalt = NO;

		newestSingleIdx    = 5;
		newestDoubleIdx[0] = 5;
		newestDoubleIdx[1] = 5;
		
		cameraMoveIdx      = 5;
	    cameraDiveIdx[0]   = 5;
		cameraDiveIdx[1]   = 5;
		
		cameraMoveState		  = NO;
		cameraDiveState		  = NO;
		
		tempCameraMovePts    = CGPointMake(0, 0);
		tempCameraDiveDistance = 0;
		
		//---- Initialization for FLIP: -------------------------------------
		rotateDirection = ROTATE_WAIT;
		theDirState     = 0;
		isRotateEnded   = YES;
		oldIsRotateEnded = YES;
		//-------------------------------------------------------------------
		
		
		
		//
		movementOne = 0;
	
	}
	
	return self;
}

- (void)drawView {

	if( sio2->_SIO2window->_SIO2windowrender )
	{
		sio2->_SIO2window->_SIO2windowrender();

		sio2WindowSwapBuffers( sio2->_SIO2window );
	}

	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)layoutSubviews {
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}

- (BOOL)createFramebuffer {
	
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);



	if( !sio2 )
	{
		sio2Init( &tmp_argc, tmp_argv );
		
		sio2InitGL();
		
		sio2InitAL();
		
		sio2->_SIO2resource = sio2ResourceInit( "default" );
		
		sio2->_SIO2window = sio2WindowInit();
	
		sio2WindowUpdateViewport( sio2->_SIO2window, 0, 0, backingWidth, backingHeight );

		sio2->_SIO2window->_SIO2windowrender = templateLoading;
		
		sio2WindowShutdown( sio2->_SIO2window, templateShutdown );
		
		sio2->_SIO2window->_SIO2windowtap			= templateScreenTap;
		sio2->_SIO2window->_SIO2windowtouchmove		= templateScreenTouchMove;
		sio2->_SIO2window->_SIO2windowaccelerometer = templateScreenAccelerometer;
		
		//added by danielbas
		sio2->_SIO2window->_SIO2windowChangeObjScl		= templateChangeObjectScale;
		sio2->_SIO2window->_SIO2windowRotateObj         = templateRotateObject;
		sio2->_SIO2window->_SIO2windowMoveObj           = templateMoveObject;
		sio2->_SIO2window->_SIO2windowMoveCamera        = templateMoveCamera;
		sio2->_SIO2window->_SIO2windowBackHandle        = backTouchHandle;
	
		
		//for rotate
		for(int i = 0 ; i < 16 ; i++){
			matrixrotate[i] = 0.0f;
		}
		matrixrotate[0] = 1.0f;
		matrixrotate[5] = 1.0f;
		matrixrotate[10] = 1.0f;
		matrixrotate[15] = 1.0f;
		
	}
	
	return YES;
}

- (void)destroyFramebuffer {
	
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)startAnimation {
	self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation {
	self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
	[animationTimer invalidate];
	animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
	
	animationInterval = interval;
	if (animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
}


- (void)dealloc {
	
	[self stopAnimation];
	
	if ([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	[context release];	
	[super dealloc];
}

// ====== Original functions of EAGLView.mm from sio2 END ======

#pragma mark -

- (BOOL) isMutipleTouchEnabled {return YES;}

- (void) backTouch:(CGPoint)point andNum:(int)num andType:(int)type {
	switch(type) {
		case 1:
			[self myTouchBegan:nil andPoint:point andFront:NO andNum: num ];
			break;
		case 2:
			[self myTouchMoved:nil andPoint:point andFront:NO andNum: num ];
			break;
		case 3:
			[self myTouchEnded:nil andPoint:point andFront:NO andNum: num ];
			break;
		default:
			break;		
	}
}

- (int) findEmpty { 
	int index;
	for(index=0; index<5; ++index){
		if(!isUsed[index]){
			isUsed[index] = YES;
			return index;
		}
	}
	return 5;
}

- (int)myTouchBegan:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num {// TODO:
	int index;
	
	movementOne++;
	
	if(isFront){
		index = [self findEmpty];
		[self.frontLoc replaceObjectAtIndex: index 
		                         withObject: [[TouchPoint alloc] initWithTouch:touch andPoint:point]
		];
		isUsed[index] = TRUE;
		//--------------------------------------------------------------------------------------------
		newestDragFrontIdx[1] = newestDragFrontIdx[0];
		newestDragFrontIdx[0] = index;
		newestFlipFrontIdx    = index;
		//--------------------------------------------------------------------------------------------		
		//--------------------------------------------------------------------------------------------
		newestSingleIdx = index;
		newestDoubleIdx[1] = newestDoubleIdx[0];
		newestDoubleIdx[0] = index;
		//--------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------
		
		fingersOnFront = TRUE;
	}
	else{
		[self.backLoc replaceObjectAtIndex: num
		                        withObject: [[TouchPoint alloc] initWithTouch:touch andPoint:point]
		];
		isUsed[num+5]=TRUE;
		//--------------------------------------------------------------------------------------------
		newestDragBackIdx[1] = newestDragBackIdx[0];
		newestDragBackIdx[0] = num;
		newestFlipBackIdx    = num;
		//--------------------------------------------------------------------------------------------
		index = num+5;
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									 sio2->_SIO2window,
									 my_WINDOW_BACK_HANDLE,
									 0,			  // useless
									 0,			  // useless
									 1,			  // type 1: Add, 2: Modify, 3: Delete
									 num,		  // index
									 point.x,     // point x
									 point.y,     // point y
									 0			  // useless
									 );
		fingersOnBack = TRUE;
	}
	
	TouchPoint *tp1, *tp2;
	// Algmented Part for DRAG: ----------------------------------------------------------------------
	if(!dragState && newestDragFrontIdx[0]<5 && newestDragBackIdx[0]<5) 
	{
		tp1 = [self.frontLoc objectAtIndex: newestDragFrontIdx[0]];
		tp2 = [self.backLoc  objectAtIndex: newestDragBackIdx[0]];
		
		if( tp1._point.x < tp2._point.x + DRAG_INITIAL_LIMIT && tp1._point.x > tp2._point.x - DRAG_INITIAL_LIMIT &&
		    tp1._point.y < tp2._point.y + DRAG_INITIAL_LIMIT && tp1._point.y > tp2._point.y - DRAG_INITIAL_LIMIT) 
		{
			dragPairIdx[0]  = newestDragFrontIdx[0];
			dragPairIdx[1]  = newestDragBackIdx[0];
			dragStartPts[0] = tp1._point;
			dragStartPts[1] = tp2._point;
			
			[self dragBegan: dragStartPts[1] ];
			
			//_StrtSystemTime = time(NULL);
		}	
	}
	// Algmented Part for FLIP: ----------------------------------------------------------------------
	if(!flipState && newestFlipFrontIdx<5 && newestFlipBackIdx<5) 
	{
		if(!dragState) 
		{ 
			newestDragBackIdx[0]  = 5;
			newestDragBackIdx[1]  = 5;
			newestDragFrontIdx[0] = 5;
			newestDragFrontIdx[1] = 5;
		}
		
		tp1 = [self.frontLoc objectAtIndex: newestFlipFrontIdx];
		tp2 = [self.backLoc  objectAtIndex: newestFlipBackIdx ];
		
		flipPairIdx[0]  = newestFlipFrontIdx;
		flipPairIdx[1]  = newestFlipBackIdx;
		flipStartPts[0] = tp1._point;
		flipStartPts[1] = tp2._point;
		
		
		
		
		[self flipBegan: flipStartPts[0] andPoint: flipStartPts[1]];
		
		isFlipX = NO;
		isFlipY = NO;
	}
	// -----------------------------------------------------------------------------------------------

	return index;
}

- (int)myTouchMoved:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num {// TODO:
	int i;
	TouchPoint* tp1;
	TouchPoint* tp2;
	if(isFront){ // compare memory location
		for(i = 0 ; i < 5 ; i++){
			tp1 = [self.frontLoc objectAtIndex:i];
			if(tp1._touch == touch){
				tp1._point = point;
				//return i;
				break;
			}
		}
	}
	else {
		tp1 = [self.backLoc objectAtIndex:num];
		tp1._point = point;
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									 sio2->_SIO2window,
									 my_WINDOW_BACK_HANDLE,
									 0,			  // useless
									 0,			  // useless
									 2,			  // type 1: Add, 2: Modify, 3: Delete
									 num,		  // index
									 point.x,     // point x
									 point.y,     // point y
									 0			  // useless
									 );
		i = num;
	}
	
	// Algmented Part For DRAG: ----------------------------------------------------------------------------------------------
	if(dragState) 
	{
		tp1 = [self.frontLoc objectAtIndex: dragPairIdx[0]];
		tp2 = [self.backLoc  objectAtIndex: dragPairIdx[1]];
		
		//if(isDebug) printf("\nFront: X=>%f Y=>%f\n",tp1._point.x,tp1._point.y);
		//if(isDebug) printf("BACK : X=>%f Y=>%f\n",tp2._point.x,tp2._point.y);
		
		if ( tp2._point.x < tp1._point.x + DRAG_MOVING_LIMIT && tp2._point.x > tp1._point.x - DRAG_MOVING_LIMIT && 
			 tp2._point.y < tp1._point.y + DRAG_MOVING_LIMIT && tp2._point.y > tp1._point.y - DRAG_MOVING_LIMIT ) {
			
			//分別Drag和Flip: 當Drag一段距離後就把_FlipState reset:
			if(flipState){
				double v1_X = tp1._point.x - dragStartPts[0].x;
				double v1_Y = tp1._point.y - dragStartPts[0].y;
				double v2_X = tp2._point.x - dragStartPts[1].x;
				double v2_Y = tp2._point.y - dragStartPts[1].y;
				
				if (sqrt((v1_X*v1_X)+(v1_Y*v1_Y)) + sqrt((v2_X*v2_X)+(v2_Y*v2_Y)) > CANCEL_LENGTH ){
					
					if ( (v1_X*v2_X + v1_Y*v2_Y)/( sqrt( (v1_X*v1_X)+(v1_Y*v1_Y) )*sqrt( (v2_X*v2_X)+(v2_Y*v2_Y) ) ) > 0 ) 
					{ 
						[self flipEnded];
					}
					
				}
				
				else [self dragMoved:tp1._point];

			}
			
			else [self dragMoved:tp1._point];

		}
		
		else [self dragEnded];
	}	
	// Algmented Part for FLIP: ----------------------------------------------------------------------------------------------
	if(flipState)
	{
		tp1 = [self.frontLoc objectAtIndex: flipPairIdx[0]];
		tp2 = [self.backLoc  objectAtIndex: flipPairIdx[1]];
		
		//if(isDebug) printf("Front: X=>%f Y=>%f\n",tp1._point.x,tp1._point.y);
		//if(isDebug) printf("BACK : X=>%f Y=>%f\n",tp2._point.x,tp2._point.y);
		
		// Check for the direction of FLIPing
		if( !isFlipX && !isFlipY){
			if( fabs(tp1._point.y-flipStartPts[0].y - tp2._point.y + flipStartPts[1].y) > FLIP_INITIAL_LIMIT ){
				isFlipY = TRUE;
			}
			else if( fabs(tp1._point.x - flipStartPts[0].x - tp2._point.x + flipStartPts[1].x) > FLIP_INITIAL_LIMIT ){
					isFlipX = TRUE;
			}
		}
		else {
			//分別Drag和Flip: 當Flip一段距離後就把_DragState reset:
			if(dragState){
				double v1_X = tp1._point.x - dragStartPts[0].x;
				double v1_Y = tp1._point.y - dragStartPts[0].y;
				double v2_X = tp2._point.x - dragStartPts[1].x;
				double v2_Y = tp2._point.y - dragStartPts[1].y;
				
				if (sqrt((v1_X*v1_X)+(v1_Y*v1_Y)) + sqrt((v2_X*v2_X)+(v2_Y*v2_Y)) > CANCEL_LENGTH ){
					
					if ( (v1_X*v2_X + v1_Y*v2_Y)/( sqrt( (v1_X*v1_X)+(v1_Y*v1_Y) )*sqrt( (v2_X*v2_X)+(v2_Y*v2_Y) ) ) < 0 ) 
					{ 
						if(isDebug) printf("Endforvector!!\n"); 
						[self dragEnded];
					}
					
				}
				
			}
			[self flipMoved:tp1._point];
		}
	}

	// -----------------------------------------------------------------------------------------------------------------------

	return i;
}

- (int)myTouchEnded:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num {// TODO:
	int i;
	TouchPoint * tempPtr;
	if(isFront){
		for(i = 0 ; i < 5 ; i++){
			tempPtr = [self.frontLoc objectAtIndex:i];
			if(tempPtr._touch == touch){
				
							
				if (newestDragFrontIdx[0] == i) newestDragFrontIdx[0] = 5;
				if (newestDragFrontIdx[1] == i) newestDragFrontIdx[1] = 5;
				if (newestFlipFrontIdx    == i) newestFlipFrontIdx    = 5;
				
				if( newestSingleIdx    == i) newestSingleIdx    = 5;
				if( newestDoubleIdx[0] == i) newestDoubleIdx[0] = 5;
				if( newestDoubleIdx[1] == i) newestDoubleIdx[1] = 5;
					
				 isUsed[i]=FALSE;
				//return i;
				break;
			}
		}
		// 計算正面touch時間
		bool hasFingers = FALSE;
		for(i = 0 ; i < 5 ; i++) hasFingers = hasFingers || isUsed[i];
		fingersOnFront = hasFingers;
	}
	else{
		
		if (dragState && dragPairIdx[1] == num) [self dragEnded];
		if (flipState && flipPairIdx[1] == num) [self flipEnded];		
		if (newestDragBackIdx[0] == num) newestDragBackIdx[0] = 5;
		if (newestDragBackIdx[1] == num) newestDragBackIdx[1] = 5;
		if (newestFlipBackIdx    == num) newestFlipBackIdx    = 5;
		
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									 sio2->_SIO2window,
									 my_WINDOW_BACK_HANDLE,
									 0,			  // useless
									 0,			  // useless
									 3,			  // type 1: Add, 2: Modify, 3: Delete
									 num,		  // index
									 point.x,     // point x
									 point.y,     // point y
									 0			  // useless
									 );
		
		isUsed[num+5] = FALSE;
		// 計算背面touch時間
		bool hasFingers = FALSE;
		for(i = 0 ; i < 5 ; i++) hasFingers = hasFingers || isUsed[i+5];
		fingersOnBack = hasFingers;
		
		i = num;
		
		//printf("----------num = %d\n",num);
	}

	return i;
	
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//Show the LogButton: ------------------------------------------------
	if(isAllTaskFinished) {
		[(templateAppDelegate*)[[UIApplication sharedApplication] delegate] showLogButton ];
	}
	
	// SIO2 part: ------------------------------------------------------
	UITouch *touch;
	CGPoint pos;
	
	sio2WindowResetTouch( sio2->_SIO2window );
	
	for( touch in touches ) {
		pos = [ touch locationInView:self ];
		sio2WindowAddTouch( sio2->_SIO2window, pos.x, pos.y );
	}
	
	sio2->_SIO2window->n_tap = [ [ touches anyObject ] tapCount ];
	
	sio2ResourceDispatchEvents( sio2->_SIO2resource,
							   sio2->_SIO2window,
							   SIO2_WINDOW_TAP,
							   SIO2_WINDOW_TAP_DOWN );
	//Both-Side Part: --------------------------------------------------
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	int i;
	int num;
	for (i=0 ; i<count ; i++) {
		// add a new touch point into multitouch.loc
		num = [self myTouchBegan:[allTouches objectAtIndex:i]
					    andPoint:[[allTouches objectAtIndex:i] locationInView:self]
					    andFront:YES
						  andNum:11 // useless 
			   ]; 
		_SameTouchIdx[i] = num;
	}
	if(count > 1){
		_SameTouchCount = count;

		[self setTouchAtSameTime: count andFront: YES];
	}
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	// SIO2 part: ---------------------------------------------------------------------
	UITouch *touch;
	CGPoint pos;
	
	sio2WindowResetTouch( sio2->_SIO2window );
	
	for( touch in touches )
	{
		pos = [ touch locationInView:self ];   //====> locationInView: returns (CGPoint)
		sio2WindowAddTouch( sio2->_SIO2window, pos.x, pos.y );
	}
		
	 sio2ResourceDispatchEvents( sio2->_SIO2resource,
								 sio2->_SIO2window,
								 SIO2_WINDOW_TOUCH_MOVE,
								 SIO2_WINDOW_TAP_DOWN );
	 
	// Both-Side Part: ----------------------------------------------------------------
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	int i, index;
	for (i=0 ; i<count ; i++) {
		
		index = [self myTouchMoved:[allTouches objectAtIndex:i]
					      andPoint:[[allTouches objectAtIndex:i] locationInView:self]
					      andFront:YES
						    andNum:11 // useless
				]; // which point in loc array is moved
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// SIO2 Part: -----------------------------------------------------------------------
	//if(isDebug) printf("@Call sio2ResourceDispatchEvents: \n");
	sio2ResourceDispatchEvents( sio2->_SIO2resource,
							   sio2->_SIO2window,
							   SIO2_WINDOW_TAP,
							   SIO2_WINDOW_TAP_UP );
	
	sio2WindowResetTouch( sio2->_SIO2window );
	
	sio2->_SIO2window->n_tap = 0;
	
	// Both-Side Part: ------------------------------------------------------------------
	NSArray *allTouches = [touches allObjects];
	int count = [allTouches count];
	int i, index;
	for (i=0 ; i<count ; i++) {
		
		index = [self myTouchEnded:[allTouches objectAtIndex:i]
					      andPoint:[[allTouches objectAtIndex:i] locationInView:self]
					      andFront:YES
						    andNum: 11
		];
	}
	
}

// more than 5 touch points -> remove all touch points
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	
	printf("TouchesCancelled ");
	//Re-initialization:-----------------------------------------------
	CGPoint point;
	self.place = [[TouchPoint alloc] initWithTouch:nil andPoint:point];
	int i;
	for( i = 0 ; i < 5 ; i++ ){
		[self.frontLoc addObject:self.place];
		[self.backLoc addObject:self.place];
	}
	
	for (i=0; i<10; i++) {
		isUsed[i] = FALSE;
	}
	
	newestDragFrontIdx[0] = 5;
	newestDragFrontIdx[1] = 5;
	newestDragBackIdx[0]  = 5;
	newestDragBackIdx[1]  = 5;
	newestFlipFrontIdx    = 5;
	newestFlipBackIdx     = 5;
	
	dragState  = NO;
	flipState  = NO;

	isFlipX    = NO;
	isFlipY    = NO;
	strtState  = NO;
	strtExpand = NO;
	isStrtHalt = NO;
	
	newestSingleIdx    = 5;
	newestDoubleIdx[0] = 5;
	newestDoubleIdx[1] = 5;
	
	//---- Initialization for FLIP: -------------------------------------
	rotateDirection = ROTATE_WAIT;
	theDirState     = 0;
	isRotateEnded   = YES;
	//-------------------------------------------------------------------
	
	//SIO2 touch points handling: ---------------------------------------
	sio2WindowResetTouch( sio2->_SIO2window );
	
	
	//-------------------------------------------------------------------
	
} 

#pragma mark -
#pragma mark Object Drag

// ================ Functions for OBJECT DRAG =================

- (void) dragBegan:(CGPoint)point {
	if (!ENABLE_OBJECT_GRAB) return;
	
	selectionPosition->x = point.x;    //Added by YO: for grab by Back-Side touch!----------------------------------------
	selectionPosition->y = 480-point.y;
	tap_select = 1; //設定物件被選取
		
	if (isDebug) printf("Drag Began\n");
	dragState = YES;
	tempDragPoint = point;
	
}

- (void) dragMoved:(CGPoint)point {
	if (!ENABLE_OBJECT_MOVE) return;
	if (isDebug) printf("Drag Moved\n");
	if(!flipState){

		int theDeltaX = point.x - tempDragPoint.x;
		int theDeltaY = point.y - tempDragPoint.y;
		
		
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									 sio2->_SIO2window,
									 my_WINDOW_MOVE_OBJ,
									 SIO2_WINDOW_TAP_DOWN,
									 0,		//scale
									 0,     //direction
									 0,     //dirState
									 (float)10*theDeltaX,     //delta x
									 (float)10*theDeltaY,     //delta y
									 0      //delta z
									 );
		
		tempDragPoint = point;
		// ------------------------------
	}
}

- (void) dragEnded {
	if (isDebug) printf("Drag End\n");
	dragState = NO;
	newestDragBackIdx[0] = 5;
	newestDragBackIdx[1] = 5;
	newestDragFrontIdx[0] = 5;
	newestDragFrontIdx[1] = 5;
	tempDragPoint = CGPointMake(0,0);
	
	if( !flipState && !strtState && selection != nil)
		[gestureSequence addObject: INTOBJ(GESTURE_BOTH_DRAG)];

}

#pragma mark Object Flip
// ================ Functions for OBJECT FLIP =================

- (void) flipBegan:(CGPoint)point andPoint:(CGPoint)pointback{
	
	if(!isRotateEnded) return;
	
	printf("\n\nFlip Began\n");
	flipState = YES;
	tempFlipPoint = point;
	
	if(!dragState){
		double changeInX = point.x - pointback.x;
		double changeInY = point.y - pointback.y;
		double xDistance = fabs(changeInX);
		double yDistance = fabs(changeInY);
		
		
		printf("point.x = %lf, point.y = %lf,  pointback.x = %lf,  pointback.y = %lf  xDistance = %lf , yDistance = %lf\n",point.x,point.y,pointback.x,pointback.y,xDistance,yDistance);
		
		//if(isDebug) printf("===== The Dirstate is: %d ======\n", theDirState);
		
		if( yDistance < 50.0 ){
			if(changeInX>0){
				if(isDebug) printf("====================== ROtate UP ============\n");
				rotateDirection = ROTATE_UP;
				isRotateEnded    = NO;
				NSTimer *timer;
				timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
														 target:self
													   selector:@selector(rotateTheObject:)
													   userInfo:nil
														repeats:YES];
				
			}
			else {
				if(isDebug) printf("====================== ROtate Down ============\n");
				rotateDirection = ROTATE_DOWN;
				isRotateEnded	 = NO;
				NSTimer *timer;
				timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
														 target:self
													   selector:@selector(rotateTheObject:)
													   userInfo:nil
														repeats:YES];
			}
			
		}
		else if( xDistance < 100.0){
			
			if(changeInY > 0){
				if(isDebug) printf("====================== ROtate RIGHT ============\n");
				rotateDirection = ROTATE_RIGHT;
				isRotateEnded    = NO;
				NSTimer *timer;
				timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
														 target:self
													   selector:@selector(rotateTheObject:)
													   userInfo:nil
														repeats:YES];
				[self increaseTheDirectionState];
			}
			else {
				if(isDebug) printf("====================== ROtate LEFT ============\n");
				rotateDirection = ROTATE_LEFT;
				isRotateEnded    = NO;
				NSTimer *timer;
				timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
														 target:self
													   selector:@selector(rotateTheObject:)
													   userInfo:nil
														repeats:YES];
				[self decreaseTheDirectionState];
			}
		}			
		// ---------------------------------------
		
	}
	
	
	
	
	//rotateDirection = ROTATE_WAIT;
	
}

- (void) flipMoved:(CGPoint)point {
	if (!ENABLE_OBJECT_FLIP) return;
	/*
	 if(isFlipX)
	 if(isDebug) printf("Flip Moved in X-direction\n");
	 else
	 if(isDebug) printf("Flip Moved in Y-direction\n");
	 
	 if(!dragState){
	 double changeInX = point.x - tempFlipPoint.x;
	 double changeInY = point.y - tempFlipPoint.y;
	 double xDistance = fabs(changeInX);
	 double yDistance = fabs(changeInY);
	 
	 //if(isDebug) printf("===== The Dirstate is: %d ======\n", theDirState);
	 
	 if( xDistance > 2*yDistance && isRotateEnded && rotateDirection == ROTATE_WAIT){
	 if(changeInX>0){
	 if(isDebug) printf("====================== ROtate UP ============\n");
	 rotateDirection = ROTATE_UP;
	 isRotateEnded    = NO;
	 NSTimer *timer;
	 timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
	 target:self
	 selector:@selector(rotateTheObject:)
	 userInfo:nil
	 repeats:YES];
	 
	 }
	 else {
	 if(isDebug) printf("====================== ROtate Down ============\n");
	 rotateDirection = ROTATE_DOWN;
	 isRotateEnded	 = NO;
	 NSTimer *timer;
	 timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
	 target:self
	 selector:@selector(rotateTheObject:)
	 userInfo:nil
	 repeats:YES];
	 }
	 
	 }
	 else if( xDistance < 2*yDistance && isRotateEnded && rotateDirection == ROTATE_WAIT){
	 
	 if(changeInY > 0){
	 if(isDebug) printf("====================== ROtate RIGHT ============\n");
	 rotateDirection = ROTATE_RIGHT;
	 isRotateEnded    = NO;
	 NSTimer *timer;
	 timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
	 target:self
	 selector:@selector(rotateTheObject:)
	 userInfo:nil
	 repeats:YES];
	 [self increaseTheDirectionState];
	 }
	 
	 else {
	 if(isDebug) printf("====================== ROtate LEFT ============\n");
	 rotateDirection = ROTATE_LEFT;
	 isRotateEnded    = NO;
	 NSTimer *timer;
	 timer = [NSTimer scheduledTimerWithTimeInterval:0.005/90
	 target:self
	 selector:@selector(rotateTheObject:)
	 userInfo:nil
	 repeats:YES];
	 [self decreaseTheDirectionState];
	 }
	 }			
	 // ---------------------------------------
	 
	 }*/
}

- (void) flipEnded {
	if(isDebug) printf("Flip End\n");
	flipState = NO;
	isFlipX   = NO;
	isFlipY   = NO;
	newestFlipFrontIdx = 5;
	newestFlipBackIdx  = 5;
	tempFlipPoint = CGPointMake(0,0);
	
	if( selection!=nil && !dragState && !strtState )
		[gestureSequence addObject: INTOBJ(GESTURE_BOTH_FLIP)];
}





- (void) setTouchAtSameTime: (int)count andFront: (BOOL)front {
	double nowTime = [NSDate timeIntervalSinceReferenceDate];
	if ((nowTime - _SameTouchFirstTime) < PUSH_INITIAL_PERIOD) {
		_PushState = 5;
		_PushFromFront = front;
		NSTimer *timer;
		timer = [NSTimer scheduledTimerWithTimeInterval: PUSH_INITIAL_WAIT_TIME 
												 target: self
											   selector: @selector(PushWaitTimer:)
											   userInfo: nil
												repeats: NO ];
	}
	
	_SameTouchFirstTime = nowTime;
}



#pragma mark Object Stretch
// ================ Functions for OBJECT STRETCH =================
- (int) TouchesOnScreen: (BOOL) isFront {
	int i, tmp;
	int count = 0;
	tmp = (isFront ? 0 : 5);
	for (i = tmp ; i < tmp + 5 ; i++){
		if (isUsed[i]) count++;
	}
	return count;
}

#pragma mark Camera Move
#pragma mark Helpful Functions for Rotation
// ============== helpful functions for rotation ==============

static int _degree_counter = 0; // Counter for rotate 90 degree

- (void) rotateTheObject:(id)sender {
	
	int testtest;
	
	if( _degree_counter == 90)
		testtest = 1;
	else 
		testtest = 0;
	
	sio2WindowResetTouch( sio2->_SIO2window );
	
	
	mysio2ResourceDispatchEvents( sio2->_SIO2resource,
								 sio2->_SIO2window,
								 my_WINDOW_ROTATE_OBJ,
								 SIO2_WINDOW_TAP_DOWN,
								 0,					//scale
								 rotateDirection,   //direction, 1: up  , 2: right, 3: down, 4: left
								 testtest,		//dirState
								 0,					//delta x
								 0,					//delta y
								 0					//delta z
								 );
	
	_degree_counter++;
	if(_degree_counter==90){
		_degree_counter=0;
		[sender invalidate];
		isRotateEnded = YES;
		printf("-----The Rotating is Ended");
	}
	
}

- (void) increaseTheDirectionState
{
	if( theDirState < 3 )  theDirState += 1;
	else                   theDirState  = 0;
}

- (void) decreaseTheDirectionState
{
	if(theDirState > 0 )  theDirState -= 1;
	else                  theDirState  = 3;
}

- (void) logButtonPredded:(id) sender
{
 	printf("taskState = %d\n",taskState);
	
	if(taskState == 0){
		printf("Start!\n");
		positionRegenerated = FALSE;
		taskState = 1;
		[(templateAppDelegate*)[[UIApplication sharedApplication] delegate] hidLogButton];
	}else{
		isReadyToLog = YES;
		printf("Start Log!\n");
		templateAppDelegate* appdel = (templateAppDelegate*)[[UIApplication sharedApplication] delegate];
		FILENAME = [[NSString alloc] initWithString:[appdel.filename text]];
		NSLog(FILENAME);
	}
}

@end
