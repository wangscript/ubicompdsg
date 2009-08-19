//
//  Multitouch.h
//  WiTap
//
//  Created by Admin on 2008/12/3.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <time.h>

@interface TouchPoint: NSObject {
	CGPoint  _point;
	//bool	 _front;
	UITouch* _touch;
}

- (TouchPoint*) initWithTouch:(UITouch*)t andPoint:(CGPoint) p ;//andFront:(bool) f;

@property (nonatomic)			CGPoint	 _point;
//@property (nonatomic)			bool     _front;
@property (nonatomic, retain)	UITouch* _touch;

@end


@interface Multitouch : UIView {
	
	NSMutableArray* backLoc;
	NSMutableArray* frontLoc;
	TouchPoint*		place;
	
	BOOL	used[10];
	/*
	BOOL	_dragState;
	int		_pairIndex[2];
	CGPoint _pairPoint[2];
	*/
	
	int		_SameTouchIdx[5];
	int		_SameTouchCount;
	double	_SameTouchFirstTime;
	BOOL	_PushFromFront;
	
	CGPoint _DragStartPts[2];
	CGPoint _FlipStartPts[2];
	

}

@property (nonatomic, retain) TouchPoint* place;
@property (nonatomic, retain) NSMutableArray* frontLoc;
@property (nonatomic, retain) NSMutableArray* backLoc;



//- (void) setTouchAtSameTime: (int)count andFront: (BOOL)front;
//- (void) PushWaitTimer: (id)sender;
- (int) touchBegan:(UITouch*)touch andPoint:(CGPoint)point andFront:(bool)front andNum:(int)num;
- (int) touchMove:(UITouch*)touch andPoint:(CGPoint)point andFront:(bool)front andNum:(int)num;
- (int) touchEnd:(UITouch*)touch andPoint:(CGPoint)point andFront:(bool)front andNum:(int)num;




@end
