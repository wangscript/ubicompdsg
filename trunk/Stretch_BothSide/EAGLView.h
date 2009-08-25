//
//  EAGLView.h
//  template
//
//  Created by SIO2 Interactive on 8/22/08.
//  Copyright SIO2 Interactive 2008. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#include "../src/sio2/sio2.h"

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/
@interface TouchPoint : NSObject
{
	CGPoint _point;
	UITouch* _touch;
}

- (TouchPoint*) initWithTouch:(UITouch*)t andPoint:(CGPoint)p ;

@property (nonatomic)         CGPoint  _point;
@property (nonatomic, retain) UITouch* _touch;

@end

@interface EAGLView : UIView {
	
	// Data Members for Both-Side touch -----------------------
	NSMutableArray* backLoc;
	NSMutableArray* frontLoc;
	TouchPoint* place;
	BOOL isUsed[10];

	BOOL cameraMoveState;
	BOOL cameraDiveState;
	int  cameraMoveIdx;
	int  cameraDiveIdx[2];
	
	BOOL dragState;
	BOOL flipState;
	BOOL strtState;
	BOOL dragOrFlipState;
	BOOL isFlipX;
	BOOL isFlipY;
	BOOL strtExpand;
	BOOL isStrtHalt;
	
	int  newestDragFrontIdx[2];
	int  newestDragBackIdx[2];
	int  newestFlipFrontIdx;
	int  newestFlipBackIdx;
	int  newestRotateXFrontIdx;
	int  newestRotateXBackIdx;	

	int  newestSingleIdx;
	int  newestDoubleIdx[2];
	
	clock_t strtSystemTime;
	double  strtPrevDistance;
	
	int dragPairIdx[2];
	int flipPairIdx[2];
	int strtPairIdx[4];
	
	CGPoint dragStartPts[2];
	CGPoint flipStartPts[2];
	
	CGPoint tempDragPoint;
	CGPoint tempFlipPoint;
	CGPoint tempRotateXPoint;
	double  tempStrtDistance; 
	 
	int		_PushState;
	int		_SameTouchIdx[5];
	int		_SameTouchCount;
	double	_SameTouchFirstTime;
	BOOL	_PushFromFront;
	
	CGPoint tempCameraMovePts;
	double  tempCameraDiveDistance;

	//------------ Bool Verivals for flip ---------------------
	int  rotateDirection;
	int  theDirState;

	//---------------------------------------------------------

@private
	
	/* The pixel dimensions of the backbuffer */
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
	GLuint depthRenderbuffer;
	
	NSTimer *animationTimer;
	NSTimeInterval animationInterval;
	
}

@property (nonatomic, retain) TouchPoint* place;
@property (nonatomic, retain) NSMutableArray* frontLoc;
@property (nonatomic, retain) NSMutableArray* backLoc;
@property NSTimeInterval animationInterval;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;

// ------- Self-Defined functions for Both-Side Touch:  -----
- (void) backTouch:(CGPoint)point andNum:(int)num andType:(int)type;
- (int) findEmpty;
- (int) myTouchBegan:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num;
- (int) myTouchMoved:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num;
- (int) myTouchEnded:(UITouch*)touch andPoint:(CGPoint)point andFront:(BOOL)isFront andNum:(int)num;

- (void) dragBegan:(CGPoint)point;
- (void) dragMoved:(CGPoint)point;
- (void) dragEnded;

- (void) flipBegan:(CGPoint)point;
- (void) flipMoved:(CGPoint)point;
- (void) flipEnded;


- (void) strtBegan:(CGPoint)point1 andPoint:(CGPoint)point2;
- (void) strtMoved:(CGPoint)point1 andPoint:(CGPoint)point2;
- (void) strtEnded;
- (void) strtHaltWithIndex:(int)idx;

- (void) setTouchAtSameTime: (int)count andFront: (BOOL)front;
- (void) PushWaitTimer: (id)sender;
- (void) PushBegan;
- (void) PushMoved: (id)sender;
- (void) PushEnded: (id)sender;
- (int) TouchesOnScreen: (BOOL) isFront;

- (void) cameraMoveBegan:(CGPoint)point;
- (void) cameraMoveMoved:(CGPoint)point;
- (void) cameraMoveEnded;

- (void) cameraDiveBegan:(CGPoint)point1 andPoint:(CGPoint)point2;
- (void) cameraDiveMoved:(CGPoint)point1 andPoint:(CGPoint)point2;
- (void) cameraDiveEnded;

- (void) increaseTheDirectionState;
- (void) decreaseTheDirectionState;

- (void) logButtonPredded:(id) sender;

@end
