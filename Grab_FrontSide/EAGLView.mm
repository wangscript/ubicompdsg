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
extern bool stateStartFlag;

extern NSMutableArray	*gestureSequence;
extern bool				fingersOnFront;
extern bool				fingersOnBack;
extern SIO2object       *selection;

extern unsigned char	tap_select;  // For GRAB Gesture
extern bool             isAllTaskFinished;
extern bool             isReadyToLog;

extern vec2				*selectionPosition;

//for flip
BOOL isRotateEnded;
BOOL oldIsRotateEnded;

extern GLfloat matrixrotate[16];
//
extern int movement[100];
extern int movementOne;
extern int movementNeeded;

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
		
		movementNeeded = 1;
	
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
		newestRotateXFrontIdx = index;
		
		fingersOnFront = TRUE;
		[self dragBegan: point];
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
		newestRotateXBackIdx = num;
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
	
	TouchPoint *tp1, *tp2, *tp3, *tp4;
	/*
	// Algmemted Part for STRETCH: -------------------------------------------------------------------
	if(!strtState) 
	{   
		//CASE1: 其中一組DragPair已經產生：
	    if(dragState && newestDragFrontIdx[0]<5 && newestDragFrontIdx[1]<5 && newestDragBackIdx[0]<5 && newestDragBackIdx[1]<5)
		{
			tp1 = [self.frontLoc objectAtIndex: newestDragFrontIdx[0]];
			tp2 = [self.backLoc  objectAtIndex: newestDragBackIdx[0]];

			if( tp1._point.x < tp2._point.x + STRETCH_INITIAL_LIMIT && tp1._point.x > tp2._point.x - STRETCH_INITIAL_LIMIT &&
			    tp1._point.y < tp2._point.y + STRETCH_INITIAL_LIMIT && tp1._point.y > tp2._point.y - STRETCH_INITIAL_LIMIT)
			{
				strtPairIdx[0] = dragPairIdx[0];
				strtPairIdx[1] = dragPairIdx[1];
				strtPairIdx[2] = newestDragFrontIdx[0];
				strtPairIdx[3] = newestDragBackIdx[0];
				
				if(strtDebug) printf("The strtPairIndex are <%d,%d><%d,%d>", strtPairIdx[0], strtPairIdx[1], strtPairIdx[2], strtPairIdx[3]);
				
				if(strtDebug) printf("From Drag!!!!\n");
				tp3 = [self.frontLoc objectAtIndex:dragPairIdx[0]];
				[self strtBegan:tp1._point  andPoint:tp3._point];
			}
		}
		//CASE2: 其中一組FlipPair已經產生：
		else if(flipState && newestFlipFrontIdx<5 && newestFlipBackIdx<5)
		{
			tp1 = [self.frontLoc objectAtIndex:newestFlipFrontIdx];
			tp2 = [self.backLoc  objectAtIndex:newestFlipBackIdx ];
			
			if( tp1._point.x < tp2._point.x + STRETCH_INITIAL_LIMIT && tp1._point.x > tp2._point.x - STRETCH_INITIAL_LIMIT &&
			    tp1._point.y < tp2._point.y + STRETCH_INITIAL_LIMIT && tp1._point.y > tp2._point.y - STRETCH_INITIAL_LIMIT)
			{
				strtPairIdx[0] = flipPairIdx[0];
				strtPairIdx[1] = flipPairIdx[1];
				strtPairIdx[2] = newestFlipFrontIdx;
				strtPairIdx[3] = newestFlipBackIdx;
				
				if(strtDebug) printf("The strtPairIndex are <%d,%d><%d,%d>\n", strtPairIdx[0], strtPairIdx[1], strtPairIdx[2], strtPairIdx[3]);
				
				if(strtDebug) printf("From FLIP!!!!\n");
				tp3 = [self.frontLoc objectAtIndex:flipPairIdx[0]];
				[self strtBegan:tp1._point andPoint:tp3._point ];
			}
		}
		//CASE3: 尚未有FlipPair或DragPair生成:
		else if(newestDragFrontIdx[0]<5 && newestDragFrontIdx[1]<5 && newestDragBackIdx[0]<5 && newestDragBackIdx[1]<5) 
		{
			tp1 = [self.frontLoc objectAtIndex: newestDragFrontIdx[0]];
			tp2 = [self.frontLoc objectAtIndex: newestDragFrontIdx[1]];
			tp3 = [self.backLoc  objectAtIndex: newestDragBackIdx[0]];
			tp4 = [self.backLoc  objectAtIndex: newestDragBackIdx[1]];
			
			if( tp1._point.x < tp3._point.x + STRETCH_INITIAL_LIMIT && tp1._point.x > tp3._point.x - STRETCH_INITIAL_LIMIT &&
			    tp1._point.y < tp3._point.y + STRETCH_INITIAL_LIMIT && tp1._point.y > tp3._point.y - STRETCH_INITIAL_LIMIT &&
			    tp2._point.x < tp4._point.x + STRETCH_INITIAL_LIMIT && tp2._point.x > tp4._point.x - STRETCH_INITIAL_LIMIT &&
			    tp2._point.y < tp4._point.y + STRETCH_INITIAL_LIMIT && tp2._point.y > tp4._point.y - STRETCH_INITIAL_LIMIT) 
			{
				strtPairIdx[0] = newestDragFrontIdx[0];
				strtPairIdx[1] = newestDragBackIdx[0];
				strtPairIdx[2] = newestDragFrontIdx[1];
				strtPairIdx[3] = newestDragBackIdx[1];
				
				if(strtDebug) printf("From Strt!!!!\n");
				if(strtDebug) printf("The strtPairIndex are <%d,%d><%d,%d>\n", strtPairIdx[0], strtPairIdx[1], strtPairIdx[2], strtPairIdx[3]);
				
				[self strtBegan:tp1._point andPoint:tp2._point];
			}
			
			else if( tp1._point.x < tp4._point.x + STRETCH_INITIAL_LIMIT && tp1._point.x > tp4._point.x - STRETCH_INITIAL_LIMIT &&
					 tp1._point.y < tp4._point.y + STRETCH_INITIAL_LIMIT && tp1._point.y > tp4._point.y - STRETCH_INITIAL_LIMIT &&
					 tp2._point.x < tp3._point.x + STRETCH_INITIAL_LIMIT && tp2._point.x > tp3._point.x - STRETCH_INITIAL_LIMIT &&
					 tp2._point.y < tp3._point.y + STRETCH_INITIAL_LIMIT && tp2._point.y > tp3._point.y - STRETCH_INITIAL_LIMIT) 
			{
				
				if(strtDebug) printf("From Strt2!!!!\n");
				strtPairIdx[0] = newestDragFrontIdx[0];
				strtPairIdx[1] = newestDragBackIdx[1];
				strtPairIdx[2] = newestDragFrontIdx[1];
				strtPairIdx[3] = newestDragBackIdx[0];	
				[self strtBegan:tp1._point andPoint:tp2._point];
			}
			
			
				
				
		}
	}
	if(strtState && isStrtHalt && newestDragBackIdx[0] < 5 && newestDragFrontIdx[0] < 5 ) //Case: Stretch Halted
	{
			if(isDebug) printf("Started from Stretch Halted ---------------\n");
			if(isDebug) printf("The newestDragFrontIdx: %d",newestDragFrontIdx[0]);
			if(isDebug) printf("The newestDragFrontIdx: %d",newestDragBackIdx[0]);
		
			tp1 = [self.frontLoc objectAtIndex: newestDragFrontIdx[0]];
			tp2 = [self.frontLoc objectAtIndex: newestDragBackIdx[0]];
			if( tp1._point.x < tp2._point.x + STRETCH_INITIAL_LIMIT && tp1._point.x > tp2._point.x - STRETCH_INITIAL_LIMIT &&
			   tp1._point.y < tp2._point.y + STRETCH_INITIAL_LIMIT && tp1._point.y > tp2._point.y - STRETCH_INITIAL_LIMIT) {
				
				strtPairIdx[2] = newestDragFrontIdx[0];
				strtPairIdx[3] = newestDragBackIdx[0];
				
				tp3 = [self.frontLoc objectAtIndex:strtPairIdx[0]];
				
				tempStrtDistance = sqrt(pow(tp1._point.x - tp3._point.x, 2)+pow(tp1._point.y - tp3._point.y, 2));
				
				isStrtHalt = NO;
			}
		
	
	}
	
	// Algmented Part for DRAG: ----------------------------------------------------------------------
	if(!strtState && !dragState && newestDragFrontIdx[0]<5 && newestDragBackIdx[0]<5) 
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
	if(!strtState && !flipState && newestFlipFrontIdx<5 && newestFlipBackIdx<5) 
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
		
		
		
		[self flipBegan: flipStartPts[0] ];
		
		isFlipX = NO;
		isFlipY = NO;
	}
	// -----------------------------------------------------------------------------------------------
	
	// 當只有偵測到一個指頭：
	if( sio2->_SIO2window->n_touch == 1 && !cameraDiveState && newestSingleIdx<5 )
	{
		if(!cameraMoveState)
		{
			tp1 = [self.frontLoc objectAtIndex: newestSingleIdx];
			cameraMoveIdx = newestSingleIdx;
			[self cameraMoveBegan:tp1._point];
		}
		else 
		{
			tp1 = [self.frontLoc objectAtIndex: newestSingleIdx];
			tp2 = [self.frontLoc objectAtIndex: cameraMoveIdx  ];
			cameraDiveIdx[0] = newestSingleIdx;
			cameraDiveIdx[1] = cameraMoveIdx;
			[self cameraMoveEnded];
			[self cameraDiveBegan:tp1._point andPoint:tp2._point];
		}
		
	}
	
	// 當偵測到兩個指頭：
	else if( sio2->_SIO2window->n_touch == 2 && !cameraMoveState && !cameraDiveState && newestDoubleIdx[0]<5 && newestDoubleIdx[1]<5 )  
	{
		tp1 = [self.frontLoc objectAtIndex: newestDoubleIdx[0]];
		tp2 = [self.frontLoc objectAtIndex: newestDoubleIdx[1]];
		cameraDiveIdx[0] = newestDoubleIdx[0];
		cameraDiveIdx[1] = newestDoubleIdx[1];
		[self cameraDiveBegan:tp1._point andPoint:tp2._point];
	}
	*/
	/*
	// Algmented Part for DRAG: ----------------------------------------------------------------------
	if( !dragState && newestDragFrontIdx[0]<5 && newestDragBackIdx[0]<5) {
		tp1 = [self.frontLoc objectAtIndex: newestDragFrontIdx[0]];
		tp2 = [self.backLoc  objectAtIndex: newestDragBackIdx[0]];
		
		if( tp1._point.x < tp2._point.x + DRAG_INITIAL_LIMIT && tp1._point.x > tp2._point.x - DRAG_INITIAL_LIMIT &&
		   tp1._point.y < tp2._point.y + DRAG_INITIAL_LIMIT && tp1._point.y > tp2._point.y - DRAG_INITIAL_LIMIT) 
		{
			//dragPairIdx[0]  = newestDragFrontIdx[0];
			//dragPairIdx[1]  = newestDragBackIdx[0];
			//dragStartPts[0] = tp1._point;
			//dragStartPts[1] = tp2._point;
			
			[self dragBegan: tp1._point];
			
			//_StrtSystemTime = time(NULL);
		}	
	}
	*/
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
		[self dragMoved:tp2._point];
	}
	/*
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
	
	// Algmented Part for STRETCH: -------------------------------------------------------------------------------------------
	if(strtState && !isStrtHalt)
	{//NOTE: 判斷stretch的move只需要判斷正面的那兩點
		tp1 = [self.frontLoc objectAtIndex: strtPairIdx[0]];
		tp2 = [self.frontLoc  objectAtIndex: strtPairIdx[2]];
		//if(strtDebug) if(isDebug) printf(" ==--> The strtPairIndex are <%d,%d><%d,%d>\n", strtPairIdx[0], strtPairIdx[1], strtPairIdx[2], strtPairIdx[3]);
		
		double strtNewDistance;
		strtNewDistance = pow( tp1._point.x - tp2._point.x, 2 ) + pow( tp1._point.y - tp2._point.y, 2);
		
		if( strtNewDistance > strtPrevDistance + STRETCH_MOVE_THRESOULD) {
			strtExpand = YES;
			[self strtMoved:tp1._point andPoint:tp2._point];
		}
		else if(strtNewDistance < strtPrevDistance - STRETCH_MOVE_THRESOULD) {														
			strtExpand = NO;
			[self strtMoved:tp1._point andPoint:tp2._point];
		}
		
	    strtPrevDistance = strtNewDistance;
	}
	// -----------------------------------------------------------------------------------------------------------------------
	
	if(cameraMoveState)
	{
		tp1 = [self.frontLoc objectAtIndex: cameraMoveIdx];
		[self cameraMoveMoved: tp1._point];
	}
	else if(cameraDiveState)
	{
		tp1 = [self.frontLoc objectAtIndex: cameraDiveIdx[0]];
		tp2 = [self.frontLoc objectAtIndex: cameraDiveIdx[1]];
		[self cameraDiveMoved: tp1._point andPoint: tp2._point];
	}
	*/

	return i;
}

- (int)myTouchEnded:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num {// TODO:
	int i;
	TouchPoint * tempPtr;
	if(isFront){
		for(i = 0 ; i < 5 ; i++){
			tempPtr = [self.frontLoc objectAtIndex:i];
			if(tempPtr._touch == touch){
				
				if (strtState && strtPairIdx[0] == num && !isStrtHalt ) [self strtHaltWithIndex:0];
				if (strtState && strtPairIdx[2] == num && !isStrtHalt ) [self strtHaltWithIndex:2];				
				if (strtState && strtPairIdx[0] == i && isStrtHalt ) [self strtEnded];
				
				if (newestDragFrontIdx[0] == i) newestDragFrontIdx[0] = 5;
				if (newestDragFrontIdx[1] == i) newestDragFrontIdx[1] = 5;
				if (newestFlipFrontIdx    == i) newestFlipFrontIdx    = 5;
				
				if( cameraMoveState && cameraMoveIdx == i) [self cameraMoveEnded];
				if( cameraDiveState && (cameraDiveIdx[0] == i || cameraDiveIdx[1] == i) ) [self cameraDiveEnded];
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
		if (strtState && strtPairIdx[1] == num && !isStrtHalt ) [self strtHaltWithIndex:1];
		if (strtState && strtPairIdx[3] == num && !isStrtHalt ) [self strtHaltWithIndex:3];
		if (strtState && strtPairIdx[1] == num && isStrtHalt ) [self strtEnded];
		
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
	/*
	newestDragBackIdx[0] = 5;
	newestDragBackIdx[1] = 5;
	newestDragFrontIdx[0] = 5;
	newestDragFrontIdx[1] = 5;
	*/
	tempDragPoint = CGPointMake(0,0);
	
	if( !flipState && !strtState && selection != nil)
		[gestureSequence addObject: INTOBJ(GESTURE_BOTH_DRAG)];

}

#pragma mark Object Flip
// ================ Functions for OBJECT FLIP =================

- (void) flipBegan:(CGPoint)point {
	
	if(!isRotateEnded) return;
	
	printf("Flip Began\n");
	flipState = YES;
	tempFlipPoint = point;
	rotateDirection = ROTATE_WAIT;
	
}

- (void) flipMoved:(CGPoint)point {
	if (!ENABLE_OBJECT_FLIP) return;
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
		
	}
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

#pragma mark Object Stretch
// ================ Functions for OBJECT STRETCH =================

- (void) strtBegan:(CGPoint)point1 andPoint:(CGPoint)point2 {  	
	if(!ENABLE_OBJECT_STRETCH) return;
	
	if(isDebug) printf("Stretch Began\n");
	strtState = YES;
	// Also Reset _DragState and _FlipState: 
	if(dragState) [self dragEnded];
	if(flipState) [self flipEnded];

	tempStrtDistance = sqrt( pow(point1.x - point2.x, 2) + pow(point1.y - point2.y,2) );
}

- (void) strtMoved:(CGPoint)point1 andPoint:(CGPoint)point2 {
	if(strtExpand) 
		if(isDebug) printf("Stretch Expand\n");
	else
		if(isDebug) printf("Stretch Shrink\n");
	
	double theDistance = sqrt( pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2) );
	double scaleIndex = theDistance - tempStrtDistance;
	
	//if(isDebug) printf("@Call sio2ResourceDispatchEvents: \n");
	if( scaleIndex>10 || scaleIndex<10){
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									 sio2->_SIO2window,
									 my_WINDOW_CHANGE_OBJ_SCALE,
									 SIO2_WINDOW_TAP_DOWN,
									 0.05*scaleIndex,  //scale
									 0,     //direction, 1: horizontal ; 2: vertical
									 0,     //dirState
									 0,     //delta x
									 0,     //delta y
									 0      //delta z
									 );
	
		tempStrtDistance = theDistance;
	}
}

- (void) strtHaltWithIndex:(int)idx {
	if(isDebug) printf("Stretch Halted\n");
	if( idx == 0 || idx == 1)
	{
		strtPairIdx[0] = strtPairIdx[2];
		strtPairIdx[1] = strtPairIdx[3];
	}
	strtPairIdx[2] = 5;
	strtPairIdx[3] = 5;
	isStrtHalt = YES;
}


- (void) strtEnded {
	if(isDebug) printf("Stretch End\n");
	strtState  = NO;
	strtExpand = NO;
	isStrtHalt = NO;
	newestDragFrontIdx[0] = 5;
	newestDragFrontIdx[1] = 5;
	newestDragBackIdx[0]  = 5;
	newestDragBackIdx[1]  = 5;
	newestFlipFrontIdx    = 5;
	newestFlipBackIdx     = 5;
	tempStrtDistance      = 0;
	
	if(selection != nil)
		[gestureSequence addObject: INTOBJ(GESTURE_BOTH_STRETCH)];
}

#pragma mark Object Push
// ================ Functions for OBJECT PUSH =================

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

- (void) PushWaitTimer: (id)sender {
	if (_PushState == 5) {
		[self PushBegan];
	}
}

- (void) PushBegan {
	if (!ENABLE_OBJECT_PUSH) return;
	
	if (_PushFromFront){
		if(isDebug) printf("Push (From Front) Began\n");
	}
	else {
		if(isDebug) printf("Push (From Back) Began\n");	
	}
	_PushState = 1;
	NSTimer *timer;
	timer = [NSTimer scheduledTimerWithTimeInterval: PUSH_PERIOD_TIME 
											 target: self
										   selector: @selector(PushMoved:)
										   userInfo: nil
											repeats: YES ];
}

- (void) PushMoved: (id)sender {
	if(_PushState > 0) {
		if ([self TouchesOnScreen: _PushFromFront] < 2){
			[self PushEnded: (id)sender];
		}
		else {
			_PushState = [self TouchesOnScreen: _PushFromFront];
		}
		if(isDebug) printf("Push (From %s) Moved, Level: %d\n", (_PushFromFront ? "Front" : "Back"), _PushState);

		double scale;
		if(!_PushFromFront) {
			switch(_PushState) {
			case 2:	scale = 5; break;
			case 3: scale = 7; break;
			case 4:	scale = 9; break;
			}
		}
		else {
			switch(_PushState) {
				case 2: scale = -5; break;
				case 3: scale = -7; break;
				case 4:	scale = -9;	break;
			}		
		}
		
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									  sio2->_SIO2window,
									  my_WINDOW_MOVE_OBJ,
									  SIO2_WINDOW_TAP_DOWN,
									  0,			//scale
									  0,			//direction, 1: horizontal ; 2: vertical
									  0,			//dirState
									  0,			//delta x
									  0,            //delta y
									  50*scale		//delta z
									 );
	
	}
}

- (void) PushEnded: (id)sender {
	[sender invalidate];
	if(isDebug) printf("Push End\n");
	_PushState = 0;
	
	if(selection!= nil)
		[gestureSequence addObject: INTOBJ(GESTURE_BOTH_PUSH)];
}

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
// ================ Functions for CAMERA MOVE =================

- (void) cameraMoveBegan:(CGPoint)point {
	if (!ENABLE_CAMERA_MOVE) return;

	//if(isDebug) if(isDebug) printf("@ Camera_Move_Began: \n");
	cameraMoveState = YES;
	tempCameraMovePts = point;
}

- (void) cameraMoveMoved:(CGPoint)point {
	//if(isDebug) if(isDebug) printf("@ Camera_Move_Moved: \n");
	
	int theDeltaX = point.x - tempCameraMovePts.x;
	int theDeltaY = point.y - tempCameraMovePts.y;
	if(!strtState && !dragState && isRotateEnded && !_PushState && cameraMoveState)
	{
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									 sio2->_SIO2window,
									 my_WINDOW_MOVE_CAMERA,
									 SIO2_WINDOW_TAP_DOWN,
									 0,  //scale
									 0,     //direction, 1: horizontal ; 2: vertical
									 0,     //dirState
									 (float)10 * theDeltaX,     //delta x
									 (float)10 * theDeltaY,     //delta y
									 0      //delta z
									 );
	}
	
	
	tempCameraMovePts = point;
	
}

- (void) cameraMoveEnded {
	//if(isDebug) if(isDebug) printf("@ Camera_Move_Ended: \n");
	cameraMoveState = NO;
	cameraMoveIdx   = 5;	
	//sio2->_SIO2camera->dir->x = 0.0f;
	//sio2->_SIO2camera->dir->y = 0.0f;
	//sio2->_SIO2camera->dir->z = 0.0f;
	if(!strtState && !dragState && isRotateEnded && !_PushState)
	{
	mysio2ResourceDispatchEvents( sio2->_SIO2resource,
								 sio2->_SIO2window,
								 my_WINDOW_MOVE_CAMERA,
								 SIO2_WINDOW_TAP_DOWN,
								 0,  //scale
								 0,     //direction, 1: horizontal ; 2: vertical
								 0,     //dirState
								 0,     //delta x
								 0,     //delta y
								 0      //delta z
								 );
	}
	
	if(YES)
		[gestureSequence addObject: INTOBJ(GESTURE_CAMERA_MOVE)];
}

#pragma mark Camera Dive
// ================ Functions for CAMERA DIVE =================

- (void) cameraDiveBegan:(CGPoint)point1 andPoint:(CGPoint)point2 {
	if (!ENABLE_CAMERA_DIVE) return;

	cameraDiveState = YES;
	tempCameraDiveDistance = sqrt( pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2) );
}

- (void) cameraDiveMoved:(CGPoint)point1 andPoint:(CGPoint)point2 {
	
	double theDistance = sqrt( pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2) );
	double scaleIndex = theDistance - tempCameraDiveDistance;

	if(!strtState && !dragState && isRotateEnded && !_PushState && cameraDiveState){
		mysio2ResourceDispatchEvents( sio2->_SIO2resource,
									  sio2->_SIO2window,
									  my_WINDOW_MOVE_CAMERA,
									  SIO2_WINDOW_TAP_DOWN,
									  0,  //scale
									  0,     //direction, 1: horizontal ; 2: vertical
								      0,     //dirState
									  0,     //delta x
									  0,     //delta y
									  10* scaleIndex      //delta z
									);
	}
	tempCameraDiveDistance = theDistance;
	
}

- (void) cameraDiveEnded {
	cameraDiveState = NO;
	cameraDiveIdx[0] = 5;
	cameraDiveIdx[1] = 5;
	
	if(YES)
		[gestureSequence addObject: INTOBJ(GESTURE_CAMERA_DIVE)];
}

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
		stateStartFlag = TRUE;
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
