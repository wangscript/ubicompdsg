/*
 *  template.mm
 *  template
 *
 *  Created by SIO2 Interactive on 8/22/08.
 *  Copyright 2008 SIO2 Interactive. All rights reserved.
 *
 */

#include <vector>
#include <time.h>
#include "template.h"

#include "../src/sio2/sio2.h"
#import <AudioToolbox/AudioToolbox.h>

using namespace std;

#define TASK_NAME				"Rotate_Flip"
#define SIO2_FILE_NAME			"Task_Rotate.sio2"
#define TASK_TOTAL_ROUND		20
#define OBJ_IN_SAME_POSISION	1
#define pi						3.1415926



NSString *FILENAME;
SystemSoundID soundID;

// ============= Shared variable between each task project ============= //
bool debug = FALSE;
//rotate
GLfloat matrixrotate[16];
BOOL isRotateEnded;
BOOL oldIsRotateEnded;
int rotateDirectionHere;
int movement[100];
int movementOne;
char taskType[TASK_TOTAL_ROUND];

vec2 *selectionPosition = sio2Vec2Init();

//-------Edit for LogButton-----------------
bool  isReadyToLog		= NO;
bool  isAllTaskFinished = NO;
bool  hadLogged         = NO;
//------------------------------------------

bool showBackTouchEnable = TRUE;

unsigned char	tap_select = 0;					// Used to check if we want to select an object
SIO2font*		_SIO2font  = NULL;				// Default font pointer used to draw info on the current selection.
SIO2object*		selection  = NULL;				// Handle of the selected object.
SIO2material*	_SIO2material_selection = NULL; // Our selection material to highlight the current selection.

bool	positionRegenerated;
char	taskState;				// Main State 
char	numberState;			// Each task square 1 ~ 4 State

double	nowTime;
double	lastTime;
double	taskStartTime;
double	taskTotalTime;
double	taskCompleteTime[TASK_TOTAL_ROUND];

// Visual Feedback: -------------------------
bool	backIsUsed[5];
vec2	backTouchPoint[5];
SIO2object*		backHoverOn[5];
int				cameraPosition;
vector<SIO2object*> frontVisual;
vector<SIO2object*> backVisual;
// ------------------------------------------

char	displayStr[ SIO2_MAX_CHAR ] = {""};

vector<SIO2object*> excludeObjects;   // Objects cannot be selected

vec2	startLoc1;
vec2	startLoc2;
float	dx1;
float	dx2;
float	dy1;
float	dy2;
float	dz;
float	det_scale;
float	_rotateAngle;

NSMutableArray *gestureSequence;  // 記錄Gesture用

bool	fingersOnFront;
bool	fingersOnFrontOld;
double	fingersOnFrontLastTime;
double	fingersOnFrontTotalTime = 0;

bool	fingersOnBack;
bool	fingersOnBackOld;
double	fingersOnBackLastTime;
double	fingersOnBackTotalTime = 0;

bool	fingersOnDevice;
bool	fingersOnDeviceOld;
double	fingersOnDeviceLastTime;
double	fingersOnDeviceTotalTime = 0;

NSDate	*taskDate = [NSDate date];

// ============= Private variable for this task project ============= //

char		nowTargetIndex;
SIO2object* rotateObject;
SIO2object* arrowObject;

SIO2material* _SIO2material_target = NULL;
bool		objectIsMoved;
bool		rotateEnable[4];

vec3		*lastRotation;
char		taskRotateDirection[TASK_TOTAL_ROUND];

// ============= Private functions for this task project ============= //

void vec3Copy(vec3* a, vec3* b) {
	a->x = b->x;
	a->y = b->y;
	a->z = b->z;
}

bool vec3Equal(vec3* a, vec3* b) {
	return (a->x == b->x) && (a->y == b->y) && (a->z == b->z);
}

void rotateEnableHandle(int dir) {
	for (int i=0 ; i<4 ; i++){
		if (i != dir) rotateEnable[i] = FALSE;
	}
	rotateEnable[dir] = TRUE;
}

void randomRotateDirection() {
	float px, py, pz , rx , ry ,rz;
	//int randnumber;
	/*while( TRUE ){
		randnumber = rand() % 4;
		printf("randnumber = %d\n",randnumber);
		if( randnumber != nowTargetIndex){
			nowTargetIndex = randnumber;
			break;
		}
	}*/
	
	if( taskState >= 1 && taskState <= 5){
		nowTargetIndex = 0;
		taskType[taskState-1] = 1;
	}
	if( taskState >= 6 && taskState <= 10){
		nowTargetIndex = 1;
		taskType[taskState-1] = 2;
	}
	if( taskState >= 11 && taskState <= 15){
		nowTargetIndex = 2;
		taskType[taskState-1] = 3;
	}
	if( taskState >= 16 && taskState <= 20){
		nowTargetIndex = 3;
		taskType[taskState-1] = 4;
	}
		
	printf("nowTargetIndex = %d\n",nowTargetIndex);
	switch( nowTargetIndex ) {
		case 0:	px = -3.3; py = -2.7; pz = 0; rx = 90; ry =  90; rz = 90; break; // 上
		case 1:	px = -3.3; py = -2.7; pz = 0; rx = 90; ry = 180; rz = 90; break; // 右
		case 2:	px = -3.3; py =  2.7; pz = 0; rx = 90; ry = 270; rz = 90; break; // 下
		case 3:	px = -3.3; py =  2.7; pz = 0; rx = 90; ry =   0; rz = 90; break; // 左
	}
	
	taskRotateDirection[taskState - 1] = nowTargetIndex;
	
	arrowObject->_SIO2transform->loc->x = px;
	arrowObject->_SIO2transform->loc->y = py;
	arrowObject->_SIO2transform->loc->z = pz;
	arrowObject->_SIO2transform->rot->x = rx;
	arrowObject->_SIO2transform->rot->y = ry;
	arrowObject->_SIO2transform->rot->z = rz;
	
	
	sio2TransformBindMatrix( arrowObject->_SIO2transform );
	
	
	rotateEnableHandle( (int) nowTargetIndex );
}

void templateRender( void ) {
	
	nowTime = [NSDate timeIntervalSinceReferenceDate];
	
	fingersOnDevice = (fingersOnFront || fingersOnBack);
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
	
	SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera" );
	
	if( !_SIO2camera ){ return; }
	
	sio2->_SIO2camera = _SIO2camera; // Bind the camera pointer.
	
	
	//-------------------------------Edit for LogButton-----------------------------
	if(isReadyToLog && !hadLogged) {
		generateLogFormat();
		hadLogged = YES;
		sprintf(displayStr, "File Had Been Logged!!");
	}
	//------------------------------------------------------------------------------
	
	if (!positionRegenerated) {
		positionRegenerated = TRUE;
		
		// ========================= 記錄手指在螢幕上時間 PART_1 =========================
		{
			switch (taskState) {
				case 1:
					if (fingersOnBack) fingersOnBackLastTime = nowTime;
					if (fingersOnFront) fingersOnFrontLastTime = nowTime;
					if (fingersOnDevice) fingersOnDeviceLastTime = nowTime;
					break;
				case TASK_TOTAL_ROUND + 2:
					if (fingersOnBack) fingersOnBackTotalTime += (nowTime - fingersOnBackLastTime);
					if (fingersOnFront) fingersOnFrontTotalTime += (nowTime - fingersOnFrontLastTime);
					if (fingersOnDevice) fingersOnDeviceTotalTime += (nowTime - fingersOnDeviceLastTime);
					break;
			}
		}
		// ==============================================================================
		
		switch(taskState){
			case 0:
				vec3Copy(lastRotation, rotateObject->_SIO2transform->rot);
				arrowObject->_SIO2transform->loc->y = 0;
				//printf("arrowObject->x = %lf , arrowObject->y = %lf\n",arrowObject->_SIO2transform->loc->x,arrowObject->_SIO2transform->loc->y);
				sio2TransformBindMatrix(arrowObject->_SIO2transform);
				strcpy( displayStr, "Select the die to START!" );
				break;
			case 1:
				//nowTargetIndex = 1;
				sprintf(displayStr, "Round: %d", taskState);
				taskStartTime = lastTime = nowTime;
				movementOne = 0;
				randomRotateDirection();
				break;
			case TASK_TOTAL_ROUND + 1:
				taskCompleteTime[taskState-2] = nowTime - lastTime;
				movement[taskState-2] = movementOne - 2;
				taskTotalTime = 0;
				for (int k=0 ; k<TASK_TOTAL_ROUND ; k++) taskTotalTime += taskCompleteTime[k];
				sprintf(displayStr, "Task Complete.");
				isAllTaskFinished = YES;   //-------------------------------Edit for LogButton-----------------
				break;
			default:
				//nowTargetIndex = 1;
				sprintf(displayStr, "Round: %d", taskState);	   
				taskCompleteTime[taskState-2] = nowTime - lastTime;
				movement[taskState-2] = movementOne - 2;
				printf("movement = %d\n",movementOne);
				movementOne = 0;
				lastTime = nowTime;
				randomRotateDirection();
				break;
		}
	}
	
	// ========================= 記錄手指在螢幕上時間 PART_2 =========================
	{
		if (taskState > 0 && taskState < TASK_TOTAL_ROUND + 2 && !isAllTaskFinished) {
			if (fingersOnBackOld != fingersOnBack) {
				if (fingersOnBack)
					fingersOnBackLastTime = nowTime;
				else
					fingersOnBackTotalTime += (nowTime - fingersOnBackLastTime);
			}
			if (fingersOnFrontOld != fingersOnFront) {
				if (fingersOnFront)
					fingersOnFrontLastTime = nowTime;
				else
					fingersOnFrontTotalTime += (nowTime - fingersOnFrontLastTime);
			}
			if (fingersOnDeviceOld != fingersOnDevice) {
				if (fingersOnDevice)
					fingersOnDeviceLastTime = nowTime;
				else
					fingersOnDeviceTotalTime += (nowTime - fingersOnDeviceLastTime);
			}
		}
		fingersOnBackOld = fingersOnBack;
		fingersOnFrontOld = fingersOnFront;
		fingersOnDeviceOld = fingersOnDevice;
	}
	// ==============================================================================
	
	if( oldIsRotateEnded == NO && isRotateEnded == YES){
	    printf("nowTargetIndex = %d , rotateDirection = %d\n", nowTargetIndex ,rotateDirectionHere );
			if(nowTargetIndex == (rotateDirectionHere)){
				taskState++;
				printf("taskstate = %d\n",taskState);
				positionRegenerated = FALSE;
				printf("You turn right! \n");
				
				
				AudioServicesPlaySystemSound(soundID);
				
				//[player play];
				
			}else{
				printf("You turn wrong! \n");
			}
	}
		oldIsRotateEnded = isRotateEnded;
	
	if( _SIO2camera )
	{
		sio2Perspective( _SIO2camera->fov,
						sio2->_SIO2window->scl->x / sio2->_SIO2window->scl->y,
						_SIO2camera->cstart,
						_SIO2camera->cend );
		
		if (taskState < TASK_TOTAL_ROUND + 1) {
			sio2WindowEnterLandscape3D();
			{
				sio2CameraRender( _SIO2camera );
				//TODO: ----------------------------- Visual Feedback -------------------------------
				cameraPosition = _SIO2camera->_SIO2transform->loc->x;
				
				// The Back-Side Touch:
				int vIndex;
				for(vIndex = 0; vIndex < 5; vIndex++)
				{
					SIO2object* obj = backVisual[vIndex];
					if(backIsUsed[vIndex])
					{
						//Showing the back-side finger on screen:
						obj->_SIO2transform->loc->x = cameraPosition - 30;  //TODO: The number should be modified latter...
						sio2TransformBindMatrix( obj ->_SIO2transform  );
						
						if(backHoverOn[vIndex] == NULL )
						{//Check if the touch point is hovering on sth:
							vec2* thePos = sio2Vec2Init();
							thePos->x = backTouchPoint[vIndex].x;
							thePos->y = 480 - backTouchPoint[vIndex].y;
							SIO2object* tempObject = sio2ResourceSelect3D( sio2->_SIO2resource,
																		  sio2->_SIO2camera,
																		  sio2->_SIO2window,
																		  thePos);
							
							//Check if the hovered obj had been excluded:
							for (int a=0 ;  a < excludeObjects.size() ; a++ ){
								if ( tempObject == excludeObjects[a] ) {
									tempObject = NULL;
									break;
								}
							}
							
							if(tempObject != NULL)
							{//Enlarge the object:
								tempObject->_SIO2transform->scl->x *= 1.1;
								tempObject->_SIO2transform->scl->y *= 1.1;
								tempObject->_SIO2transform->scl->z *= 1.1;
								sio2TransformBindMatrix2( tempObject->_SIO2transform,matrixrotate,-1.0f,0.0f,0.0f , 2);
								backHoverOn[vIndex] = tempObject;
							}
							
						}
						else if( backHoverOn[vIndex] != NULL)
						{//Check if the touch point is still hovering on sth:
							vec2* thePos = sio2Vec2Init();
							thePos->x = backTouchPoint[vIndex].x;
							thePos->y = 480 - backTouchPoint[vIndex].y;
							SIO2object* tempObject = sio2ResourceSelect3D( sio2->_SIO2resource,
																		  sio2->_SIO2camera,
																		  sio2->_SIO2window,
																		  thePos);
							
							if( tempObject != backHoverOn[vIndex])
							{ //the touch point is not hovering on sth:
								backHoverOn[vIndex]->_SIO2transform->scl->x /= 1.10;
								backHoverOn[vIndex]->_SIO2transform->scl->y /= 1.10;
								backHoverOn[vIndex]->_SIO2transform->scl->z /= 1.10;
								sio2TransformBindMatrix2( backHoverOn[vIndex]->_SIO2transform,matrixrotate,-1.0f,0.0f,0.0f , 2);
								backHoverOn[vIndex] = NULL;
							}
							
						}
					}
					else
					{
						//Not showing the back-side finger:
						obj->_SIO2transform->loc->x = cameraPosition - 200;
						sio2TransformBindMatrix( obj ->_SIO2transform  );
					}
					
					
				}
				// Rendering objects:
				glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
				
				sio2CameraUpdateFrustum( sio2->_SIO2camera );
				sio2ResourceCull( sio2->_SIO2resource, sio2->_SIO2camera );		
				sio2ResourceRender( sio2->_SIO2resource,
								   sio2->_SIO2window,
								   sio2->_SIO2camera,
								   SIO2_RENDER_SOLID_OBJECT);
				
				// Make Selection: ------------------------------------------------------------------
				for(int i=0; i<5; i++)
				{
					SIO2object* obj = frontVisual[i];
					obj->_SIO2transform->loc->x = cameraPosition - 200;
					sio2TransformBindMatrix( obj ->_SIO2transform );
				}	
				
				if ( tap_select && selection != rotateObject) {
					tap_select = 0;
					
					glClear( GL_COLOR_BUFFER_BIT ); // Clear the color buffer
					sio2MaterialReset();            // Reset the material states
					
					if(sio2->_SIO2window->n_touch != 0) {
						if (GRAB_WITH_BACK_TOUCH) {
							selection = sio2ResourceSelect3D( sio2->_SIO2resource,
															 sio2->_SIO2camera,
															 sio2->_SIO2window,
															 selectionPosition);
						}
						else {
							selection = sio2ResourceSelect3D( sio2->_SIO2resource,
															 sio2->_SIO2camera,
															 sio2->_SIO2window,
															 sio2->_SIO2window->touch[0]);
						}
					}
					
					// Selection 例外處理：不能select的物件
					for (int a=0 ; a<excludeObjects.size() ; a++ ){
						if ( selection == excludeObjects[a] ) {
							selection = nil;
							break;
						}
					}
					if (selection == rotateObject) {
						positionRegenerated = FALSE;
						taskState = 1;
					}
				}
				
				// Visual Feedback for Front-Touch:
				for(vIndex = 0; vIndex < 5; vIndex++)
				{	
					SIO2object* obj = frontVisual[ vIndex ];
					if( vIndex < sio2->_SIO2window->n_touch)
					{// Showing the plane indicating the front-touch:
						vec2 frontPosition;
						frontPosition.x = sio2->_SIO2window->touch[ vIndex ]->x;
						frontPosition.y = sio2->_SIO2window->touch[ vIndex ]->y;
						obj->_SIO2transform->loc->x = cameraPosition - 5;
						obj->_SIO2transform->loc->y = 0.0095*( frontPosition.x - 480/2);
						obj->_SIO2transform->loc->z = 0.0095*( frontPosition.y - 320/2);
						sio2TransformBindMatrix( obj ->_SIO2transform );
					}
					else
					{
						obj->_SIO2transform->loc->y = cameraPosition + 200;
						sio2TransformBindMatrix( obj ->_SIO2transform );
					}
				}				

				
				sio2CameraUpdateFrustum( sio2->_SIO2camera );
				sio2ResourceCull( sio2->_SIO2resource, sio2->_SIO2camera );		
				sio2ResourceRender( sio2->_SIO2resource,
								   sio2->_SIO2window,
								   sio2->_SIO2camera,
								   SIO2_RENDER_SOLID_OBJECT  );
				//Visual Feedback for Selection ( including initializing the selection material):
				if(selection)
				{
					if(!_SIO2material_selection)
					{
						//Initialize the material:
						_SIO2material_selection = sio2MaterialInit("selection");
						
						// Initialize some component of the color
						_SIO2material_selection->diffuse->z = 0.0f;
						_SIO2material_selection->diffuse->w = 0.35f;
						
						// Change the blending mode
						_SIO2material_selection->blend = SIO2_MATERIAL_COLOR;
					}
					
					// Set to red
					_SIO2material_selection->diffuse->x = 1.0f;
					_SIO2material_selection->diffuse->y = 0.0f;
					
					// Render the material
					sio2MaterialRender( _SIO2material_selection );
					
					sio2ObjectRender( selection, sio2->_SIO2window, sio2->_SIO2camera, 0, SIO2_TRANSFORM_MATRIX_BIND );
				}
				sio2ResourceRender( sio2->_SIO2resource,
								   sio2->_SIO2window,
								   sio2->_SIO2camera,
								   SIO2_RENDER_TRANSPARENT_OBJECT);				
				sio2ObjectReset();
				sio2MaterialReset();
			}
			// Leave the landscape mode.
			sio2WindowLeaveLandscape3D();
		}
		
		sio2WindowEnter2D( sio2->_SIO2window, 0.0f, 1.0f );
		{
			// Draw back-side point
			if (ENABLE_SHOW_BACK_TOUCH){
				const GLfloat squareVertices[] = {
					-3.0f, -3.0f,
					3.0f, -3.0f,
					-3.0f,  3.0f,
					3.0f,  3.0f,
				};
				for (int i=0 ; i<5 ; i++){
					if (!backIsUsed[i]) continue;
					glVertexPointer( 2, GL_FLOAT, 0, squareVertices );
					glEnableClientState( GL_VERTEX_ARRAY );
					
					glPushMatrix();
					{
						glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
						glTranslatef( backTouchPoint[i].x, 480 - backTouchPoint[i].y, 0.0f );
						glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);	
					}
					glPopMatrix();
				}
			}
			// Show text on the screen
			if (ENABLE_SHOW_TEXT) {
				sio2WindowEnterLandscape2D( sio2->_SIO2window );
				{
					vec2 pos;
					glPushMatrix();
					{
						float scl;
						
						scl = 1.9f;
						
						glScalef( scl, scl, scl );
						// -----------------------------------------
						sio2->_SIO2material = NULL;
						
						pos.x = 0.0f;
						pos.y = 480 / scl - 16.0f;
						
						/*_SIO2font->_SIO2material->diffuse->x = 0.0f;
						_SIO2font->_SIO2material->diffuse->y = 1.0f;
						_SIO2font->_SIO2material->diffuse->z = 1.0f;
						sio2FontPrint( _SIO2font, &pos, displayStr, NULL);
						*/
						 // -----------------------------------------
					}
					glPopMatrix();
					sio2FontReset();
					sio2MaterialReset();
				}
				sio2WindowLeaveLandscape2D( sio2->_SIO2window );
			}
		}
		sio2WindowLeave2D();
	}
}

void templateLoading( void ) {
	unsigned int i = 0;
	
	//AUDIO

	CFURLRef ding = (CFURLRef)[ [NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource: @"ding" ofType:@"wav" ]];
	AudioServicesCreateSystemSoundID( ding, &soundID);

	
	
	srand ( time(NULL) );
	taskState = 0;
	positionRegenerated = FALSE;
	lastRotation = sio2Vec3Init();
	nowTime = taskStartTime =  [NSDate timeIntervalSinceReferenceDate];
	for(int k=0 ; k<5 ; k++){
		backIsUsed[k] = FALSE;
	}
	
	_SIO2material_selection = NULL;
	
	sio2ResourceCreateDictionary( sio2->_SIO2resource );
	
	sio2ResourceOpen( sio2->_SIO2resource, SIO2_FILE_NAME, 1 );
	
	while( i != sio2->_SIO2resource->gi.number_entry ) {
		sio2ResourceExtract( sio2->_SIO2resource, NULL );
		++i;
	}
	
	// ADD BY EARLY
	templatePrintProgress();
	
	sio2ResourceClose( sio2->_SIO2resource );
	sio2ResetState();
	sio2ResourceBindAllImages( sio2->_SIO2resource );
	sio2ResourceBindAllMaterials( sio2->_SIO2resource );
	sio2ResourceBindAllInstances( sio2->_SIO2resource );
	sio2ResourceBindAllMatrix( sio2->_SIO2resource );
	
	// Generate the geometry VBO.
	sio2ResourceGenId( sio2->_SIO2resource );
	
	rotateObject = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Cube" );
	arrowObject  = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Arrow" );
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Arrow" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Plane" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Plane2" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Plane3" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Plane4" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Plane5" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF1" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF2" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF3" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF4" ));
	excludeObjects.push_back(( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF5" ));
	
	frontVisual.push_back((SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF1"));
	frontVisual.push_back((SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF2"));
	frontVisual.push_back((SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF3"));
	frontVisual.push_back((SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF4"));
	frontVisual.push_back((SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/PlaneF5"));
	backVisual.push_back( (SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/Plane"));
	backVisual.push_back( (SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/Plane2"));
	backVisual.push_back( (SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/Plane3"));
	backVisual.push_back( (SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/Plane4"));
	backVisual.push_back( (SIO2object*)sio2ResourceGet(sio2->_SIO2resource, SIO2_OBJECT, "object/Plane5"));
	
	sio2->_SIO2window->_SIO2windowrender = templateRender;
	
}

// ============= Shared functions between each task project ============= //

void templateShutdown( void ) {
	
	sio2ResourceUnloadAll( sio2->_SIO2resource );
	
	sio2->_SIO2resource = sio2ResourceFree( sio2->_SIO2resource );
	
	sio2->_SIO2window = sio2WindowFree( sio2->_SIO2window );
	
	sio2 = sio2Shutdown();
	
	printf("\nSIO2: shutdown...\n" );
}


void templatePrintProgress( void ) {	
/*	if( !_SIO2font )
	{
		SIO2image	 *_SIO2image    = NULL;
		SIO2material *_SIO2material = NULL;
		SIO2stream	 *_SIO2stream	= NULL;
		
		_SIO2stream = sio2StreamOpen( "default16x16.tga", 1 );
		
		if( _SIO2stream )
		{
			_SIO2image = sio2ImageInit( "default16x16.tga" );
			{
				sio2ImageLoad( _SIO2image, _SIO2stream );
				
				sio2ImageGenId( _SIO2image, 0 );
			}
			_SIO2stream = sio2StreamClose( _SIO2stream );
			
			_SIO2material = sio2MaterialInit( "default16x16" );
			{
				_SIO2material->blend = SIO2_MATERIAL_ALPHA;
				_SIO2material->_SIO2image[ SIO2_MATERIAL_CHANNEL0 ] = _SIO2image;
			}
			
			_SIO2font = sio2FontInit( "default16x16" );
			
			_SIO2font->_SIO2material = _SIO2material;
			
			_SIO2font->n_char = 16;
			_SIO2font->size   = 16.0f;
			_SIO2font->space  = 8.0f;
			
			sio2FontBuild( _SIO2font );
		}	
	}
	
	
	glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
*/	
}

void templateScreenTap( void *_ptr, unsigned char _state ) {
	
	if( _state == SIO2_WINDOW_TAP_DOWN && sio2->_SIO2window->n_touch==1)
	{
		startLoc1.x = sio2->_SIO2window->touch[ 0 ]->x;
		startLoc1.y = sio2->_SIO2window->touch[ 0 ]->y;
	}
	else if( _state == SIO2_WINDOW_TAP_DOWN && sio2->_SIO2window->n_touch==2)
	{
		startLoc2.x = sio2->_SIO2window->touch[ 1 ]->x;
		startLoc2.y = sio2->_SIO2window->touch[ 1 ]->y;
		
	}
	if( _state == SIO2_WINDOW_TAP_UP )
	{
		dx1 = 0.0f;
		dx2 = 0.0f;
		dy1 = 0.0f;
		dy2 = 0.0f;
		dz = 0.0f;
	}
	
}

void templateScreenTouchMove( void *_ptr ) {
	
}

void templateScreenAccelerometer( void *_ptr ){
	
}
void templateChangeObjectScale( void *_ptr, float det_scale) {
	
	SIO2object *_SIO2object = selection;
	
	if( _SIO2object )
	{
		
		//SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera");
		if(debug) printf("_SIO2object->_SIO2transform->scl->x = %f \n", _SIO2object->_SIO2transform->scl->x);
        det_scale *= 0.1;
		if(_SIO2object->_SIO2transform->scl->x + det_scale < 3 && _SIO2object->_SIO2transform->scl->x + det_scale > 0.1)
		{
			_SIO2object->_SIO2transform->scl->x += det_scale;
			_SIO2object->_SIO2transform->scl->y += det_scale;
			_SIO2object->_SIO2transform->scl->z += det_scale;
		}
		
		//sio2TransformBindMatrix( _SIO2object->_SIO2transform  );
		sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate,-1.0f,0.0f,0.0f , 2);
	}
	
	
}
void templateRotateObject( void *_ptr , int rotateDirection, int theDirState ) {
	
	rotateDirectionHere = rotateDirection-1;
	SIO2object *_SIO2object = selection;
	if( _SIO2object )
	{
		//_rotateAngle = 0.0f;
		switch(rotateDirection){
			case 1:{ //Rotate-Up
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate,0.0f,1.0f,0.0f , 1);
				break;
			}
		      case 2:{ //Rotate-Right
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate,1.0f,0.0f,0.0f , 1);
				break;
			}
			case 3:{ //Rotate-Down
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate,0.0f,-1.0f,0.0f , 1);
				break;
			}
		      case 4:{//Rotate-Left		
				
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate,-1.0f,0.0f,0.0f , 1);
				break;
			}
			case 5:{//Rotate-X
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate, 0.0f,0.0f,1.0f , 1);
				break;			
				
			}
			default:break;
				
		}
		
	}
	
}

void templateMoveObject( void *_ptr ,float _detX, float _detY, float _detZ ) {	
/*	
	SIO2object *_SIO2object = selection;
	
	// Check if we get a pointer.
	if( _SIO2object )
	{
		// Apply a rotation based on the touch movement.
		SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera");
		float k = sio2Distance(_SIO2camera->_SIO2transform->loc, _SIO2object->_SIO2transform->loc) * 0.0001;
		
		// Moving object in Z axis
		if(fabsf(_detX) > 0.01)
		{
			if(debug) printf("\nDETX!!!");
			if(_SIO2object->_SIO2transform->loc->z + _detX * k < 100 && _SIO2object->_SIO2transform->loc->z + _detX * k > -100)
	    	{
				_SIO2object->_SIO2transform->loc->z += _detX * k;
		    }
     	}
		if(fabsf(_detY) > 0.01)
		{
			if(debug) printf("\nDETY!!!");
			if(_SIO2object->_SIO2transform->loc->y + _detY * k < 100 && _SIO2object->_SIO2transform->loc->y + _detY * k > -100)
			{
				_SIO2object->_SIO2transform->loc->y += _detY * k;
			}
		}
		
		if(fabs(_detZ) > 0.01)
		{
			if(debug) printf("\nDETZ!!!");
			if(_SIO2object->_SIO2transform->loc->x + _detZ * k < 100 && _SIO2object->_SIO2transform->loc->x + _detZ * k > -100)
			{
				_SIO2object->_SIO2transform->loc->x += _detZ * k; 
			}
			if(debug) printf("X: %f\n",_SIO2object->_SIO2transform->loc->x);
		}
		
		
		//sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate, 0.0f, 0.0f, 0.0f , 2);
		
		sio2TransformBindMatrix( _SIO2object->_SIO2transform  );
	}
*/ 
}
 

void templateMoveCamera( void *_ptr ,float _detX, float _detY, float _detZ ) {	
/*	
	SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera");
	float k = _SIO2camera->_SIO2transform->loc->x * 0.0005;
	
	if(fabsf(_detX) >50){
		if(_SIO2camera->_SIO2transform->loc->z - _detX * 0.001 < 100 && _SIO2camera->_SIO2transform->loc->z - _detX * 0.001 > 1.0)
		{
			_SIO2camera->_SIO2transform->loc->z -= _detX * k * 0.1;
			//_SIO2camera->_SIO2transform->tar->z -= _detX * k * 0.1;
		}
	}
	
	if(fabsf(_detY) >50){
		if(_SIO2camera->_SIO2transform->loc->y - _detY * 0.001 < 100 && _SIO2camera->_SIO2transform->loc->y - _detY * 0.001 > 1.0)
		{
			_SIO2camera->_SIO2transform->loc->y -= _detY * k * 0.1;
			//_SIO2camera->_SIO2transform->tar->z -= _detX * k * 0.1;
		}
	}
	
	if(_SIO2camera->_SIO2transform->loc->x - _detZ * 0.005 < 100 && _SIO2camera->_SIO2transform->loc->x - _detZ * 0.005 > 0.0)
	{
		_SIO2camera->_SIO2transform->loc->x -= _detZ * 0.005;
		//_SIO2camera->_SIO2transform->tar->x -= _detZ * 0.005;
	}
	
 */
}

void backTouchHandle(void *_ptr, int type, int index, float pt_x, float pt_y) {
	vec2 pt;
	pt.x = pt_x;
	pt.y = pt_y;
	
	switch (type) {
		case 1: // Add a point
			backIsUsed[index] = TRUE;
			backTouchPoint[index] = pt;
			
			//Reset the position of the plane indicating the back-side finger:
			SIO2object* obj1 = backVisual[index];
			if(obj1)
			{
				obj1->_SIO2transform->loc->z = 0.057* ( pt.x - 320/2) ;
				obj1->_SIO2transform->loc->y = 0.057* ( pt.y - 480/2);
			}
			break;
		case 2: // Modify a point
			
			//Move the plane indicating the back-side finger:
			SIO2object* obj2 = backVisual[index];
			if(obj2)
			{
				vec2 d; 
				d.x = pt.x - backTouchPoint[index].x;
				d.y = pt.y - backTouchPoint[index].y;
				
				obj2->_SIO2transform->loc->z += d.x*0.057;
				obj2->_SIO2transform->loc->y += d.y*0.057;
			}
			
			backTouchPoint[index] = pt;
			
			break;
		case 3: // Delete a point
			backIsUsed[index] = FALSE;
			
			if(backHoverOn[index] != NULL)
			{ //Shrink the obj had been hovered on:
				backHoverOn[index]->_SIO2transform->scl->x /= 1.10;
				backHoverOn[index]->_SIO2transform->scl->y /= 1.10;
				backHoverOn[index]->_SIO2transform->scl->z /= 1.10;
				sio2TransformBindMatrix( backHoverOn[index]->_SIO2transform  );
				backHoverOn[index] = NULL;
			}
			break;
	}
	
}

void generateLogFormat() {
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString* taskDateString = [dateFormatter stringFromDate: taskDate];
	
	NSMutableString *textCSV = [NSMutableString stringWithCapacity: 20];
	NSMutableString *textAll = [NSMutableString stringWithCapacity: 20];
	NSMutableString *textLog = [NSMutableString stringWithCapacity: 20];
	NSString *bundleName = [[NSString alloc] initWithString: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleDisplayName"]];
	
	[textLog appendFormat: @"### %@ %@ ###\n", bundleName , taskDateString];
	
	float avgMovement = 0;
	for (int i=0; i < TASK_TOTAL_ROUND ; i++){
		[textCSV appendFormat: @"%@,%d,%d,%.3f,%d\n",bundleName, taskType[i], i+1, taskCompleteTime[i], movement[i]];
		[textLog appendFormat: @"%d\t%d\t%.3f\t%d\n", i+1, taskType[i], taskCompleteTime[i], movement[i]];
		avgMovement += movement[i];
	}
	avgMovement /= TASK_TOTAL_ROUND;
	[textAll appendFormat: @"%@,%@,%@,%.3f,%.3f,%.3f,%.3f,%.3f\n",FILENAME,bundleName,taskDateString,taskTotalTime,
	 fingersOnFrontTotalTime,fingersOnBackTotalTime,fingersOnDeviceTotalTime,avgMovement];
	
	[textLog appendFormat: @"\nTotal time:        %.3f\nFingers on front:  %.3f\nFingers on back:   %.3f\nFingers on device: %.3f\nAvg Extra movement: %.3f\n\n", 
	 taskTotalTime, fingersOnFrontTotalTime, fingersOnBackTotalTime, fingersOnDeviceTotalTime, avgMovement];
	
	logToFile(textCSV, [NSString stringWithFormat: @"%@_CSV.csv",FILENAME]);
	logToFile(textLog, [NSString stringWithFormat: @"%@_LOG.txt",FILENAME]);
	logToFile(textAll, [NSString stringWithFormat: @"All_CSV.CSV"]);
}


void logToFile(NSString *logText, NSString *fileName) {
	
	NSString *path = @"/User/Media/DCIM";
	NSArray *pathComponents = [path pathComponents];
	NSString *testPath = [NSString pathWithComponents:pathComponents];
	NSString		*appFile = [testPath stringByAppendingPathComponent: FILENAME];
	NSFileManager	*fm = [NSFileManager defaultManager];
	NSData			*data;
	
	data = [logText dataUsingEncoding: NSASCIIStringEncoding];
	
	if ([fm fileExistsAtPath: appFile] == NO){
		[fm createFileAtPath: appFile contents: data attributes: nil];
	}
	
	else{
		NSFileHandle	*outFile;
		outFile = [NSFileHandle fileHandleForUpdatingAtPath: appFile];
		[outFile seekToEndOfFile];
		[outFile writeData: data];
		[outFile closeFile];
	}	
	
}
