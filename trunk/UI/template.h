/*
 *  template.h
 *  template
 *
 *  Created by SIO2 Interactive on 8/22/08.
 *  Copyright 2008 SIO2 Interactive. All rights reserved.
 *
 */

#ifndef TEMPLATE_H
#define TEMPLATE_H

#define GRAB_WITH_BACK_TOUCH	YES

#define ENABLE_OBJECT_GRAB		YES
#define ENABLE_OBJECT_MOVE		YES
#define ENABLE_OBJECT_PUSH		YES
#define ENABLE_OBJECT_FLIP		YES
#define ENABLE_OBJECT_STRETCH	YES

#define ENABLE_CAMERA_DIVE		YES
#define ENABLE_CAMERA_MOVE		YES

#define ENABLE_SHOW_BACK_TOUCH	YES
#define	ENABLE_SHOW_TEXT		YES

#include "../src/sio2/sio2.h"

typedef enum {
	GESTURE_BOTH_GRAB = 0,
	GESTURE_BOTH_DRAG,
	GESTURE_BOTH_PUSH,
	GESTURE_BOTH_FLIP,
	GESTURE_BOTH_STRETCH,
	GESTURE_SINGLE_GRAB,
	GESTURE_SINGLE_DRAG,
	GESTURE_SINGLE_PUSH,
	GESTURE_SINGLE_FLIP,
	GESTURE_SINGLE_STRETCH,
	GESTURE_SINGLE_BUTTON_CAMERA,
	GESTURE_SINGLE_BUTTON_MOVE,
	GESTURE_SINGLE_BUTTON_SCALE,
	GESTURE_CAMERA_MOVE,
	GESTURE_CAMERA_DIVE
} GESTURE_EVENT;

void templateRender( void );

void templateLoading( void );

void templateShutdown( void );

void templateScreenTap( void *_ptr, unsigned char _state );

void templateScreenTouchMove( void *_ptr );

void templateScreenAccelerometer( void *_ptr );

//added by danielbas{
void templateChangeObjectScale( void *_ptr, float det_scale);

void templateRotateObject( void *_ptr , int rotateDirection, int theDirState);  //1: up, 2: right, 3: down, 4: left

void templateMoveObject( void *_ptr ,float _detX, float _detY, float _detZ);

void templateMoveCamera( void *_ptr ,float _detX, float _detY, float _detZ );

//} added by danielbas

void backTouchHandle(void *_ptr, int type, int index, float pt_x, float pt_y);

void logToFile(NSString *logText, NSString *fileName);

// Help Functions For Visual Feedback:
void sortingTheObjects();

void RenderTransparentObject ( SIO2object* obj );

void RenderSolidObject( SIO2object* obj);

bool checkForGroup( SIO2object* oFront, SIO2object* oBack );

#endif
