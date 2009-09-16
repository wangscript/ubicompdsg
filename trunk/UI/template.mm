

#include <time.h>
#include "template.h"
#include "../src/sio2/sio2.h"
#include <vector>
using namespace std;


#define TASK_NAME				"Template"
#define SIO2_FILE_NAME			"UIdemo.sio2"
#define TASK_TOTAL_ROUND		5

#define OBJ_IN_SAME_POSISION	1
#define pi						3.1415926

#define TARTET_ROT_X_1			0
#define TARTET_ROT_Y_1			90
#define TARTET_ROT_Z_1			0
#define TARTET_ROT_X_2			0
#define TARTET_ROT_Y_2			270
#define TARTET_ROT_Z_2			180
#define TAR_OBJ_DIS_THRESHOLD	1
#define TAR_OBJ_SCL_THRESHOLD	0.2
#define JG_GAME_AFILTER SIO2_IMAGE_ANISOTROPIC_1X
#define JG_GAME_TFILTER	SIO2_IMAGE_QUADLINEAR


#pragma mark -

//rotate
//GLfloat matrixrotate[16];
vector < GLfloat[16] > rotatingMatrixs;

// ============= Shared variable between each task project ============= //

vec2* selectionPosition;
vec2* frontSelectPosition;
vec2* backSelectPosition;

bool debug = NO;

//-------Edit for "Full Screen"-------------
bool isFullScreen = NO;

//-------Edit for LogButton-----------------
bool  isReadyToLog		= NO;
bool  isAllTaskFinished = NO;
bool  hadLogged         = NO;
//------------------------------------------
unsigned char	tap_select = 0;					// Used to check if we want to select an object
unsigned char  front_select = 0;
unsigned char  back_select = 0;


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

bool	backIsUsed[5];
vec2	backTouchPoint[5];

char	displayStr[ SIO2_MAX_CHAR ] = {""};

vector<SIO2object*> excludeObjects;         // Objects cannot be selected
vector< theObject*> theSortedObjects;
vector<SIO2object*> theSelectedGroup;
vector<SIO2object*> theIconList;


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
bool	fingersOnBack;
bool	fingersOnDevice;
bool	fingersOnFrontOld;
double	fingersOnFrontLastTime  = 0;
double	fingersOnFrontTotalTime = 0;
bool	fingersOnDeviceOld;
double	fingersOnDeviceLastTime;
double	fingersOnDeviceTotalTime;
bool	fingersOnBackOld;
double	fingersOnBackLastTime;
double	fingersOnBackTotalTime;

NSDate	*taskDate = [NSDate date];

// ============= Private variable for this task project ============= //

SIO2object	*selectObject;
SIO2object	*targetObject;
SIO2camera	*camera;
SIO2thread  *videoThread;
SIO2object  *fire;

vec3		*cameraOrignalPos;
vec3		*cameraOrignalTar;
vec3		*objectOrignalScl;

int			showNumber;
bool		checkPos;
bool		checkScl;
bool		checkRot;

// ============= Private functions for this task project ============= //
/*
void vec4Create(vec4* vec, float w, float x, float y, float z) {
	vec->w = w;
	vec->x = x;
	vec->y = y;
	vec->z = z;
}

void vec4Copy(vec4* a, vec4* b) {
	a->w = b->w;
	a->x = b->x;
	a->y = b->y;
	a->z = b->z;
}

void vec3Copy(vec3* a, vec3* b) {
	a->x = b->x;
	a->y = b->y;
	a->z = b->z;
}

bool vec3BlurEqual(vec3* a, vec3* b, float threshold) {
	return (
			( fabsf( a->x - b->x ) <= threshold )	
			&&  ( fabsf( a->y - b->y ) <= threshold )
			&&	( fabsf( a->z - b->z ) <= threshold )
			);
}

bool rotationEqual() {
	int n;
	int y = (int)selectObject->_SIO2transform->rot->y;
	int z = (int)selectObject->_SIO2transform->rot->z;
	switch(y) {
		case   0:
			switch (z){
				case   0: n = 5; break;
				case  90: n = 4; break;
				case 180: n = 2; break;
				case 270: n = 3; break;
			}
			break;
		case  90:
			switch (z){
				case   0: n = 6; break;
				case  90: n = 4; break;
				case 180: n = 1; break;
				case 270: n = 3; break;
			}
			break;
		case 180:
			switch (z){
				case   0: n = 2; break;
				case  90: n = 4; break;
				case 180: n = 5; break;
				case 270: n = 3; break;
			}
			break;
		case 270:
			switch (z){
				case   0: n = 1; break;
				case  90: n = 4; break;
				case 180: n = 6; break;
				case 270: n = 3; break;
			}
			break;
	}
	
	return showNumber == n;
}
*/
bool pointInBox(vec3* pt, vec3* box_center, float scl) {
	return (   fabsf(pt->x - box_center->x) < scl 
			&& fabsf(pt->y - box_center->y) < scl
			&& fabsf(pt->z - box_center->z) < scl
			);
}
/*
void generatePosition() {
	float x1, y1, z1, x2, y2, z2, scl;
	
	switch( taskState ){
		case 1: x1 = 31; y1 = 10; z1 =  5; x2 =  3; y2 =  3; z2 =  3; scl = 2.0; showNumber = 6; break;
		case 2: x1 =  5; y1 =  3; z1 = 12; x2 = 15; y2 =  3; z2 =  3; scl = 1.5; showNumber = 1; break;
		case 3: x1 =  5; y1 =  5; z1 =  3; x2 = 12; y2 = 10; z2 = 12; scl = 2.5; showNumber = 4; break;
		case 4: x1 = 17; y1 = 12; z1 =  8; x2 =  5; y2 = 11; z2 =  4; scl = 3.0; showNumber = 2; break;
		case 5: x1 =  5; y1 =  6; z1 =  4; x2 = 17; y2 =  3; z2 =  4; scl = 0.8; showNumber = 3; break;
	}
	
	selectObject->_SIO2transform->loc->x = x1;
	selectObject->_SIO2transform->loc->y = y1;
	selectObject->_SIO2transform->loc->z = z1;
	targetObject->_SIO2transform->loc->x = x2;
	targetObject->_SIO2transform->loc->y = y2;
	targetObject->_SIO2transform->loc->z = z2;
	targetObject->_SIO2transform->scl->x = targetObject->_SIO2transform->scl->y = targetObject->_SIO2transform->scl->z = scl;
	
	vec3Copy( camera->_SIO2transform->loc, cameraOrignalPos );
	//vec3Copy( camera->_SIO2transform->tar, cameraOrignalTar);
	vec3Copy( selectObject->_SIO2transform->scl, objectOrignalScl );
	
	sio2TransformBindMatrix( selectObject->_SIO2transform );
	sio2TransformBindMatrix( targetObject->_SIO2transform );
}

void recordGestureSequence() {
	
	NSArray *gestureName = [NSArray arrayWithObjects:	@"BOTH_GRAB",				@"BOTH_DRAG",
							@"BOTH_PUSH",				@"BOTH_FLIP",
							@"BOTH_STRETCH",
							@"SINGLE_GRAB",				@"SINGLE_DRAG",
							@"SINGLE_PUSH",				@"SINGLE_FLIP",
							@"SINGLE_STRETCH",	
							@"SINGLE_BUTTON_CAMERA",	@"SINGLE_BUTTON_MOVE",
							@"SINGLE_BUTTON_SCALE",
							@"CAMERA_MOVE",				@"CAMERA_DIVE",
							nil];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"MM-dd-HH-mm"];
	NSString* taskDateString = [dateFormatter stringFromDate: taskDate];
	
	NSMutableString *text = [NSMutableString stringWithCapacity: 20];
	
	for (int i=0 ; i<[gestureSequence count] ; i++){
		int a = [[gestureSequence objectAtIndex: i] intValue];
		[text appendFormat:@"%d,%d,%@\n", taskState-1, a, [gestureName objectAtIndex: a]];
	}
	
	logToFile(text, [NSString stringWithFormat:@"%s_GST_%@.txt", TASK_NAME, taskDateString]);
	
	[gestureSequence removeAllObjects];
	
}

void generateLogFormat() {
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString* taskDateString = [dateFormatter stringFromDate: taskDate];
	
	NSMutableString *textCSV = [NSMutableString stringWithCapacity: 20];
	NSMutableString *textLog = [NSMutableString stringWithCapacity: 20];
	
	[textLog appendFormat: @"### %s %@ ###\n", TASK_NAME, taskDateString];
	
	for (int i=0; i < TASK_TOTAL_ROUND ; i++){
		[textCSV appendFormat: @"%@,%d,%.3f,%.3f,%.3f,%.3f\n",taskDateString, i+1, taskCompleteTime[i], fingersOnFrontTotalTime, fingersOnBackTotalTime, fingersOnDeviceTotalTime];
		[textLog appendFormat: @"%d\t%.3f\n", i+1, taskCompleteTime[i]];
	}
	
	[textLog appendFormat: @"\nTotal time:        %.3f\nFingers on front:  %.3f\nFingers on back:   %.3f\nFingers on device: %.3f\n\n", 
	 taskTotalTime, fingersOnFrontTotalTime, fingersOnBackTotalTime, fingersOnDeviceTotalTime];
	
	logToFile(textCSV, [NSString stringWithFormat: @"%s_CSV.csv", TASK_NAME]);
	logToFile(textLog, [NSString stringWithFormat: @"%s_LOG.txt", TASK_NAME]);
}
*/


@implementation theObject

@synthesize _obj;
@synthesize _icon;
@synthesize _originalScl;
@synthesize _theLocBeforeFullScreen;
@synthesize _isMinimized;
@synthesize _angleForMinimizing;

- (theObject*) initWithSIO2Object:( SIO2object*) newObject andIcon: ( SIO2object* ) newIcon ;
{
	if (self) {
		
		_obj		= newObject;
		_obj->dst	= 1.0f;
		_icon		= newIcon;
		_icon->dst	= 1.0f;
		
		_originalScl = sio2Vec3Init();
		_originalScl->x = newObject->_SIO2transform->scl->x;
		_originalScl->y = newObject->_SIO2transform->scl->y;
		_originalScl->z = newObject->_SIO2transform->scl->z;
		
		_theLocBeforeFullScreen = sio2Vec3Init();
		_theLocBeforeFullScreen->x = newObject->_SIO2transform->loc->x;
		_theLocBeforeFullScreen->y = newObject->_SIO2transform->loc->y;
		_theLocBeforeFullScreen->z = newObject->_SIO2transform->loc->z;
		
		_isMinimized = false;
		_angleForMinimizing = 0.0;
		
		for( int i=0; i<16; i++)
		{
			_rotateMatrix[ i ] = 0.0f;
		}
		_rotateMatrix[0]	= 1.0f;
		_rotateMatrix[5]	= 1.0f;
		_rotateMatrix[10]	= 1.0f;
		_rotateMatrix[15]	= 1.0f;
	}
	return self;
}

- ( GLfloat* ) getRotatingMatrix
{
	return _rotateMatrix;
}

- ( void ) setRotatingMatrix: ( GLfloat* ) newMatrix
{
	for( int i=0; i<16; i++)
	{
		_rotateMatrix[i] = newMatrix[i];
	}
}

@end



#pragma mark -
#pragma mark SIO2 template

void templateRender( void ) {
	
	
	// Initialize the thread that will stream the
	// sound and videos.
	if( !videoThread )
	{
		// Initialize the thread
		videoThread = sio2ThreadInit();
		
		// Create the thread giving it a high priority.
		// This priority should give good results on iPhone
		// as well as iPod Touch. A priorty of thread too
		// high will degrade the overall performance.
		sio2ThreadCreate( videoThread,
						  videoPlayThread,
						  ( void * )NULL,
						  SIO2_THREAD_PRIORITY_NORMAL );
		
		// Start the thread.
		sio2ThreadPlay( videoThread );
		
	}
	
	
	nowTime = [NSDate timeIntervalSinceReferenceDate];
	
	fingersOnDevice = (fingersOnFront || fingersOnBack);
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
	
	SIO2camera* _SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA, "camera/Camera" );
	SIO2object* fire        = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Window"   );
	
	if( !_SIO2camera ){ return; }
	
	sio2->_SIO2camera = _SIO2camera; // Bind the camera pointer.

	// Make sure that we found the camera
	if( _SIO2camera )
	{
		sio2Perspective( _SIO2camera->fov,
						sio2->_SIO2window->scl->x / sio2->_SIO2window->scl->y,
						_SIO2camera->cstart,
						_SIO2camera->cend );
		
#pragma mark Rendering:
		
		sio2WindowEnterLandscape3D();
		{
			
			sio2CameraRender( _SIO2camera );
			sortingTheObjects();
			
			sio2CameraUpdateFrustum( sio2->_SIO2camera );
			sio2ResourceCull( sio2->_SIO2resource, sio2->_SIO2camera );	
			
			// Update the fire video if one of the lantern is          //add by moje
			// visible.                                                //add by moje
			sio2ExecLUA( "video.render_fire();" );                     //add by moje

#pragma mark Selection:
			if ( tap_select && !isFullScreen ) {
				
				theSelectedGroup.clear();
				tap_select = 0;
				
				glClear( GL_COLOR_BUFFER_BIT ); // Clear the color buffer
				
				double cameraPosition = camera->_SIO2transform->loc->x;
				
				for( int i=0; i < theSortedObjects.size(); i++)
				{
					GLfloat _M [16];
					for( int k=0; k<16; k++)
					{
						_M[ k ] = [ theSortedObjects[ i ] getRotatingMatrix ][k];
					}
					
					theSortedObjects[ i ]._obj ->_SIO2transform->loc->x = cameraPosition + ( cameraPosition - theSortedObjects[ i ]._obj ->_SIO2transform->loc->x );
					sio2TransformBindMatrix2( theSortedObjects[ i ]._obj ->_SIO2transform, _M, 0.0f,0.0f,0.0f , 2 );
					[ theSortedObjects[i] setRotatingMatrix: _M ];
				}
				
				for(int i = theSortedObjects.size()-1 ; i >= 0; i-- )
				{
					GLfloat _M [16];
					for( int k=0; k<16; k++)
					{
						_M[ k ] = [ theSortedObjects[ i ] getRotatingMatrix ][k];
					}
					theSortedObjects[ i ]._obj->_SIO2transform->loc->x = cameraPosition - ( theSortedObjects[ i ]._obj ->_SIO2transform->loc->x - cameraPosition );
					sio2TransformBindMatrix2( theSortedObjects[ i ]._obj ->_SIO2transform, _M, 0.0f,0.0f,0.0f , 2 );
					[ theSortedObjects[i] setRotatingMatrix: _M ];
					
					// Edit for "Minimizing":
					if( !theSortedObjects[i]._isMinimized)
						RenderSolidObject( theSortedObjects[ i ]._obj );
					else 
						RenderSolidObject( theSortedObjects[ i ]._icon);
					
					if( sio2->_SIO2window->n_touch != 0 ) {
						if (GRAB_WITH_BACK_TOUCH) {
							glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
							sio2MaterialReset();            // Reset the material states
							sio2DisableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							selection = sio2ResourceSelect3D( sio2->_SIO2resource,
													   sio2->_SIO2camera,
													   sio2->_SIO2window,
													   selectionPosition);
							sio2EnableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
						}
						else {
							glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
							sio2DisableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							selection = sio2ResourceSelect3D( sio2->_SIO2resource,
															 sio2->_SIO2camera,
															 sio2->_SIO2window,
															 sio2->_SIO2window->touch[0]);
							sio2EnableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
						}
					}
					
					/* 重疊處理
					if (selection == targetObject) {
						if (pointInBox(selectObject->_SIO2transform->loc, targetObject->_SIO2transform->loc, targetObject->_SIO2transform->scl->x))
							selection = selectObject;
						else if (selectObject->_SIO2transform->loc->x + selectObject->_SIO2transform->scl->x < targetObject->_SIO2transform->loc->x - targetObject->_SIO2transform->scl->x)
							selection = selectObject;
					}*/
					
					// Selection 例外處理：不能select的物件
					for (int a=0 ; a<excludeObjects.size() ; a++ ){
						if ( selection == excludeObjects[a] ) {
							selection = nil;
							break;
						}
					}
					
					
					for( int j=0; j < theSelectedGroup.size(); j++ )
					{
						if( selection == theSelectedGroup[ j ] )
						{
							selection = nil;
							break;
						}
					}
					
					if(selection)
						theSelectedGroup.push_back(selection);
				}
				
				// Edit for Minimizing:
				// if any "Icon" is selected, enlargement of the minimized app. is triggered:
				if( theSelectedGroup.size() > 0)
				{
					for( int k=0; k<theSelectedGroup.size(); k++)
					{
						for( int m=0; m<theSortedObjects.size(); m++)
						{
							if( theSortedObjects[m]._icon == theSelectedGroup[k])
							{
								theSelectedGroup.clear();
								enlargeTheMinimizedApp( theSortedObjects[m] );
								break;
							}
						}
						
						if( theSelectedGroup.size() == 0) break;
					}
				}
				
			}
			else if( ( front_select || back_select)  && !isFullScreen )
			{
				theSelectedGroup.clear();
				double cameraPosition = camera->_SIO2transform->loc->x;
				
				if(back_select)
				{
					for( int index=0; index < theSortedObjects.size(); index++)
					{
						GLfloat _M [16];
						for( int k=0; k<16; k++)
						{
							_M[ k ] = [ theSortedObjects[ index ] getRotatingMatrix ][k];
						}
						theSortedObjects[ index ]._obj ->_SIO2transform->loc->x = cameraPosition + ( cameraPosition - theSortedObjects[ index ]._obj ->_SIO2transform->loc->x );
						sio2TransformBindMatrix2( theSortedObjects[ index ]._obj ->_SIO2transform, _M, 0.0f,0.0f,0.0f , 2 );
						[ theSortedObjects[ index ] setRotatingMatrix: _M ];
						
					}
					
					back_select = 0;
					selection = nil;
					for( int index = theSortedObjects.size()- 1; index>=0; index--) // TODO-02
					{
						GLfloat _M [16];
						for( int k=0; k<16; k++)
						{
							_M[ k ] = [ theSortedObjects[ index ] getRotatingMatrix ][k];
						}
						theSortedObjects[ index ]._obj ->_SIO2transform->loc->x = cameraPosition - ( theSortedObjects[ index ]._obj ->_SIO2transform->loc->x - cameraPosition );
						sio2TransformBindMatrix2( theSortedObjects[ index ]._obj ->_SIO2transform, _M, 0.0f,0.0f,0.0f , 2 );
						[ theSortedObjects[ index ] setRotatingMatrix: _M ];
						RenderSolidObject( theSortedObjects[ index ]._obj  );
						
						if (GRAB_WITH_BACK_TOUCH) {
							glClear( GL_COLOR_BUFFER_BIT ); // Clear the color buffer
							sio2MaterialReset();            // Reset the material states
							sio2DisableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							selection = sio2ResourceSelect3D( sio2->_SIO2resource,
															 sio2->_SIO2camera,
															 sio2->_SIO2window,
															 backSelectPosition );
							sio2EnableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
						}
						
						/* 重疊處理
						if (selection == targetObject) {
							if (pointInBox(selectObject->_SIO2transform->loc, targetObject->_SIO2transform->loc, targetObject->_SIO2transform->scl->x))
								selection = selectObject;
							else if (selectObject->_SIO2transform->loc->x + selectObject->_SIO2transform->scl->x < targetObject->_SIO2transform->loc->x - targetObject->_SIO2transform->scl->x)
								selection = selectObject;
						}*/
						
						// Selection 例外處理：不能select的物件
						for (int a=0 ; a<excludeObjects.size() ; a++ ){
							if ( selection == excludeObjects[a] ) {
								selection = nil;
								break;
							}
						}
						
						
						for( int j=0; j < theSelectedGroup.size(); j++ )
						{
							if( selection == theSelectedGroup[ j ] )
							{
								selection = nil;
								break;
							}
						}
						
						if(selection)
						{
							theSelectedGroup.push_back(selection);
							for( int k = index-1; k >= 0; k--)
							{ // Render the rest objects in theSortedObjects:
								GLfloat _M [16];
								for( int l =0; l <16; l ++)
								{
									_M[ l ] = [ theSortedObjects[ k ] getRotatingMatrix ][l];
								}
								theSortedObjects[ k ]._obj ->_SIO2transform->loc->x = cameraPosition - ( theSortedObjects[ k ]._obj ->_SIO2transform->loc->x - cameraPosition );
								sio2TransformBindMatrix2( theSortedObjects[ k ]._obj ->_SIO2transform, _M, 0.0f,0.0f,0.0f , 2 );
								[ theSortedObjects[ k ] setRotatingMatrix: _M ];
								RenderSolidObject( theSortedObjects[ k ]._obj  );								
							}
							break;                                          //JUMP OUT OF THE FORLOOP.
						}
						
					}
				}
				else if(front_select)
				{
					
					for( int k=0; k<theSortedObjects.size(); k++)   // TODO-01
					{
						SIO2object* tempObj = theSortedObjects[k]._obj;
						RenderSolidObject( tempObj );
					}
					
					front_select = 0;
					selection = nil;
					if( sio2->_SIO2window->n_touch != 0 ) {
						if (GRAB_WITH_BACK_TOUCH) {
							
							glClear( GL_COLOR_BUFFER_BIT ); // Clear the color buffer
							sio2MaterialReset();            // Reset the material states
							sio2DisableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							selection = sio2ResourceSelect3D( sio2->_SIO2resource,
													   sio2->_SIO2camera,
													   sio2->_SIO2window,
													   frontSelectPosition );
							sio2EnableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
							glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
						}
					}
					
					/* 重疊處理
					if (selection == targetObject) {
						if (pointInBox(selectObject->_SIO2transform->loc, targetObject->_SIO2transform->loc, targetObject->_SIO2transform->scl->x))
							selection = selectObject;
						else if (selectObject->_SIO2transform->loc->x + selectObject->_SIO2transform->scl->x < targetObject->_SIO2transform->loc->x - targetObject->_SIO2transform->scl->x)
							selection = selectObject;
					}*/
					
					// Selection 例外處理：不能select的物件
					for (int a=0 ; a<excludeObjects.size() ; a++ ){
						if ( selection == excludeObjects[a] ) {
							selection = nil;
							break;
						}
					}
					
					
					for( int j=0; j < theSelectedGroup.size(); j++ )
					{
						if( selection == theSelectedGroup[ j ] )
						{
							selection = nil;
							break;
						}
					}
					
					if(selection)
					{
						theSelectedGroup.push_back(selection);
					}
					
				}
			}

			else
			{
				sio2ResourceRender( sio2->_SIO2resource,
								   sio2->_SIO2window,
								   sio2->_SIO2camera,
								   SIO2_RENDER_SOLID_OBJECT );
				
				//Rendering the video object:
				
				sio2DisableState( &fire->flags, SIO2_OBJECT_INVISIBLE );
				sio2ObjectRender( fire,
								  sio2->_SIO2window,
								  sio2->_SIO2camera,
								  1, SIO2_TRANSFORM_MATRIX_BIND );
				sio2EnableState(  &fire->flags, SIO2_OBJECT_INVISIBLE);
			}

			
			// 有選到東西的的話做highlight
			for( int index=0; index < theSelectedGroup.size(); index++)
			{
				selection = theSelectedGroup[ index ];
				if( selection )	{				
					if( !_SIO2material_selection )
					{
						// Initialize the material
						_SIO2material_selection = sio2MaterialInit( "selection" );
						
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
			}
			// Render all the alpha objects currently inside the frustum.
			sio2ResourceRender( sio2->_SIO2resource,
							   sio2->_SIO2window,
							   sio2->_SIO2camera,
							   SIO2_RENDER_TRANSPARENT_OBJECT );
			
            //fire
			{
				sio2DisableState( &fire->flags   , SIO2_OBJECT_INVISIBLE );
				
				sio2ObjectRender( fire,
								 sio2->_SIO2window,
								 sio2->_SIO2camera,
								 1, SIO2_TRANSFORM_MATRIX_BIND );
				
				sio2EnableState( &fire->flags   , SIO2_OBJECT_INVISIBLE );              // video end by moje
            }
			
			sio2ObjectReset();			
			sio2MaterialReset();
			
		}
		sio2WindowLeaveLandscape3D();
		
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
			
			if (ENABLE_SHOW_TEXT) {
				sio2WindowEnterLandscape2D( sio2->_SIO2window );
				{
					//vec2 pos;
					glPushMatrix();
					{
						// -----------------------------------------
						sio2->_SIO2material = NULL;

						_SIO2font->_SIO2transform->loc->x = 8.0f;
						_SIO2font->_SIO2transform->loc->y = sio2->_SIO2window->scl->y - 16.0f;
						
						_SIO2font->_SIO2material->diffuse->x = 0.0f;
						_SIO2font->_SIO2material->diffuse->y = 1.0f;
						_SIO2font->_SIO2material->diffuse->z = 1.0f;
						
						sio2FontPrint( _SIO2font,
									  SIO2_TRANSFORM_MATRIX_APPLY,
									  "Renderer FPS: %.0f",
									  sio2->_SIO2window->fps );
						// -----------------------------------------
					}
					glPopMatrix();

					sio2FontReset();
					sio2MaterialReset();
					
					//sio2WindowDebugTouch( sio2->_SIO2window );
				}
				sio2WindowLeaveLandscape2D( sio2->_SIO2window );
			}
			
		}
		sio2WindowLeave2D();
		
	}
}

void templatePrintProgress( void )
{
	if( !_SIO2font )
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
				
				sio2ImageGenId( _SIO2image, NULL, 0.0f );
			}
			_SIO2stream = sio2StreamClose( _SIO2stream );
			
			_SIO2material = sio2MaterialInit( "default16x16" );
			{
				_SIO2material->blend = SIO2_MATERIAL_COLOR;
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
}

void templateLoading( void ) {
	
	//ADD by YO: for selection from Back-Side touch:
	selectionPosition = sio2Vec2Init();
	frontSelectPosition = sio2Vec2Init();
	backSelectPosition = sio2Vec2Init();

	unsigned int i = 0;
	
	srand ( time(NULL) );
	taskState = 0;
	positionRegenerated = FALSE;
	nowTime = taskStartTime =  [NSDate timeIntervalSinceReferenceDate];
	for(int k=0	 ; k<5 ; k++){
		backIsUsed[k] = FALSE;
	}
	
	gestureSequence = [[NSMutableArray alloc] init];
	
	
	sio2->_SIO2resource = sio2ResourceInit( "jgGarden" );	
		// Initialize a physic world.
	sio2->_SIO2physic = sio2PhysicInit( "jgGarden" );
	
	sio2ResourceCreateDictionary( sio2->_SIO2resource );
	sio2->tfilter = JG_GAME_TFILTER;
	sio2->afilter = JG_GAME_AFILTER;
	
	
	sio2ResourceOpen( sio2->_SIO2resource, SIO2_FILE_NAME, 1 );
	
	
	// Loop into the archive extracting all the 
	// resources compressed within the fileformat.
	while( i != sio2->_SIO2resource->gi.number_entry )
	{
		sio2ResourceExtract( sio2->_SIO2resource, JG_GAME_PASSWORD );
		++i;
	}
	
	// ADD BY EARLY
	templatePrintProgress();
	
	// We are done with the file so close the stream.
//	sio2ResourceClose( sio2->_SIO2resource );
//	sio2ResetState();
	sio2ResourceBindAllMatrix( sio2->_SIO2resource );
	sio2ResourceBindAllImages( sio2->_SIO2resource );
	sio2ResourceBindAllMaterials( sio2->_SIO2resource );
	sio2ResourceBindAllSoundBuffers( sio2->_SIO2resource );  
	sio2ResourceBindAllInstances( sio2->_SIO2resource );
	sio2ResourceBindAllPhysicObjects( sio2->_SIO2resource,
									 sio2->_SIO2physic );   // add by moje
	//sio2ResourceBindAllInstances( sio2->_SIO2resource );
	
	
	SIO2video *_SIO2video;        //video start: by moje
	// Fire
	{
		_SIO2video = sio2VideoInit( "fire" );
		
		_SIO2video->_SIO2stream = sio2StreamInit( "fire" );
		
		sio2ResourceExtractFile( sio2->_SIO2resource,
								_SIO2video->_SIO2stream,
								"image/fire.ogv",
								JG_GAME_PASSWORD );
		
		sio2VideoLoad( _SIO2video, _SIO2video->_SIO2stream );
		
		sio2VideoPlay( _SIO2video, 1 );
	}
	
		sio2ExecLUA( "video.init();" );
	
//	static SIO2object *fire    = sio2ResourceGetObject( sio2->_SIO2resource,
//													   "object/fire" );
//	sio2DisableState( &fire->flags   , SIO2_OBJECT_INVISIBLE );
	
	//	sio2ObjectRender( fire,
	//					 sio2->_SIO2window,
	//					 sio2->_SIO2camera,
	//					 1, SIO2_TRANSFORM_MATRIX_BIND );
	
//	sio2EnableState( &fire->flags   , SIO2_OBJECT_INVISIBLE );              // video end by moje
	
	
	
	
	
	sio2ResourceGenId( sio2->_SIO2resource );
	fire         = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/fire" );

#pragma mark Definition of Vectors:

	theSortedObjects.push_back( [ [ theObject alloc ] initWithSIO2Object: (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Window")  
																 andIcon: (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Icon")]);
	theSortedObjects.push_back( [ [ theObject alloc ] initWithSIO2Object: (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Window2") 
																 andIcon: (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Icon2")]);
	theSortedObjects.push_back( [ [ theObject alloc ] initWithSIO2Object: (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Window3") 
																 andIcon: (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Icon3")]);
	
	//theIconList.push_back( (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Icon"));
	//theIconList.push_back( (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Icon2"));
	//theIconList.push_back( (SIO2object*)sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Icon3"));

		
	camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera" );

	//Sort the Objects:
	sortingTheObjects();
	
	selection = selectObject;
	
	sio2->_SIO2window->_SIO2windowrender = templateRender;
}

// =============================================================================

void templateShutdown( void ) {
	
	sio2ResourceUnloadAll( sio2->_SIO2resource );
	
	videoThread = sio2ThreadFree( videoThread );
	
	sio2->_SIO2resource = sio2ResourceFree( sio2->_SIO2resource );
	
	sio2->_SIO2window = sio2WindowFree( sio2->_SIO2window );
	
	sio2 = sio2Shutdown();
	
	printf("\nSIO2: shutdown...\n" );
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

void templateScreenAccelerometer( void *_ptr ) {
	
}

#pragma mark -
#pragma mark Object & Camera Transform Handle

void templateChangeObjectScale( void *_ptr, float det_scale) 
{
	if( theSelectedGroup.size() > 0)
	{
		
		det_scale *= 0.1;
		SIO2object* _SIO2object = nil;
		int index = theSortedObjects.size();
		
		//Finding the selected obj whitch is nearest to the camera: 
		for( int i= theSelectedGroup.size()-1; i >= 0; i--)
		{
			int tempIndex;
			for( int k=0; k<theSortedObjects.size(); k++)
			{
				if( theSelectedGroup[i] == theSortedObjects[k]._obj)
				{
					tempIndex = k;
					break;
				}
				
				
			}
			
			if( tempIndex < index)
				index = tempIndex;
			
		}
		
		
		{
			GLfloat _M[16];
			
			for( int s=0; s<16; s++)
				_M[s] = [ theSortedObjects[index] getRotatingMatrix ][s];
			
			_SIO2object = theSortedObjects[index]._obj;
			
			
			if( _SIO2object )
			{
				
				//SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera");
				if(debug) printf("_SIO2object->_SIO2transform->scl->y = %f \n", _SIO2object->_SIO2transform->scl->y );
				
				if(_SIO2object->_SIO2transform->scl->y + det_scale < 14 - 2.5*index && _SIO2object->_SIO2transform->scl->y + det_scale > 1.5 )
				{
					//_SIO2object->_SIO2transform->scl->x += det_scale;   // Do not increase the thickness of windows.
					_SIO2object->_SIO2transform->scl->y += det_scale;
					_SIO2object->_SIO2transform->scl->z += det_scale * _SIO2object->_SIO2transform->scl->z / _SIO2object->_SIO2transform->scl->y;
					
					printf(" ==== The scale of obj is: %f \n", _SIO2object->_SIO2transform->scl->y );
				}
				else if( _SIO2object->_SIO2transform->scl->y + det_scale >=14 - 2.5*index )
				{
					fullScreenSetup( index, _SIO2object );
				}
				
				//sio2TransformBindMatrix( _SIO2object->_SIO2transform  );
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M, 0.0f,0.0f,0.0f , 2);
				[ theSortedObjects[ index ] setRotatingMatrix: _M ];
			}
		}
		
		
	}
}

void templateRotateObject( void *_ptr , int rotateDirection, int theDirState ) {
	
	if( theSelectedGroup.size() != 1 ) 
	{// Not dealing with Multi-Objects-Rotation for now.	
		return;
	}
	
	SIO2object* _SIO2object;
	GLfloat _M[16];
	int index;
	
	for( int i=0; i<theSortedObjects.size(); i++)
	{
		if( theSortedObjects[ i ]._obj == theSelectedGroup[ 0 ] )
		{
			_SIO2object = theSortedObjects[ i ]._obj ;
			for( int k=0; k<16; k++)
			{
				_M[ k ] = [ theSortedObjects[ i ] getRotatingMatrix ][k];
			}
			index = i;
			break;
		}
	}
	

	
	
	if( _SIO2object )
	{
		//_rotateAngle = 0.0f;
		switch(rotateDirection){
			case 1:{ //Rotate-Up
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M,0.0f,1.0f,0.0f , 1);
				[ theSortedObjects[ index ] setRotatingMatrix: _M];
				break;
			}
		    case 2:{ //Rotate-Right
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M,1.0f,0.0f,0.0f , 1);
				[ theSortedObjects[ index ] setRotatingMatrix: _M];
				break;
			}
			case 3:{ //Rotate-Down
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M,0.0f,-1.0f,0.0f , 1);
				[ theSortedObjects[ index ] setRotatingMatrix: _M];
				break;
			}
		    case 4:{//Rotate-Left		
	
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M,-1.0f,0.0f,0.0f , 1);
				[ theSortedObjects[ index ] setRotatingMatrix: _M];
				break;
			}
			case 5:{//Rotate-X
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M, 0.0f,0.0f,1.0f , 1);
				[ theSortedObjects[ index ] setRotatingMatrix: _M];
				break;			
			
			}
			default:break;
				
		}
		
	}
	
}

void templateMoveObject( void *_ptr ,float _detX, float _detY, float _detZ ) {	

	if( theSelectedGroup.size() > 0)
	{
		for( int i=0;  i < theSelectedGroup.size(); i++)
		{
			GLfloat _M[16];
			SIO2object *_SIO2object = nil;
			int index;
			
			for( int k=0; k<theSortedObjects.size(); k++)
			{
				if( theSortedObjects[k]._obj == theSelectedGroup[i])
				{
					for( int l=0; l<16; l++)
						_M[l] = [ theSortedObjects[k] getRotatingMatrix][l] ;
					
					_SIO2object = theSortedObjects[k]._obj; 
					index = k;
					break;
				}
			}
			
			// Check if we get a pointer.
			if( _SIO2object )
			{
				// Apply a rotation based on the touch movement.
				SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera");
				float k = sio2Distance(_SIO2camera->_SIO2transform->loc, _SIO2object->_SIO2transform->loc) * 0.0001;
				
				
				if(fabsf(_detX) > 0.01)
				{
					if(debug) printf("\nDETX!!!");
					if(_SIO2object->_SIO2transform->loc->z + _detX * k < 100 && _SIO2object->_SIO2transform->loc->z + _detX * k > _SIO2object->_SIO2transform->scl->x)
					{
						_SIO2object->_SIO2transform->loc->z += _detX * k;
					}
				}
				if(fabsf(_detY) > 0.01)
				{
					if(debug) printf("\nDETY!!!");
					if(_SIO2object->_SIO2transform->loc->y + _detY * k < 100 && _SIO2object->_SIO2transform->loc->y + _detY * k > _SIO2object->_SIO2transform->scl->x)
					{
						_SIO2object->_SIO2transform->loc->y += _detY * k;
					}
				}
				
				if(fabs(_detZ) > 0.01)  //Implimentation for Gesture: PUSH
				{
					if(debug) printf("\nDETZ!!!");
					// if(_SIO2object->_SIO2transform->loc->x + _detZ  < 100 && _SIO2object->_SIO2transform->loc->x + _detZ  > _SIO2object->_SIO2transform->scl->x)
					{
						_SIO2object->_SIO2transform->loc->x += _detZ ; 
					}
					if(debug) printf("X: %f\n",_SIO2object->_SIO2transform->loc->x);
				}
				
				
				sio2TransformBindMatrix2(_SIO2object->_SIO2transform,_M, 0.0f, 0.0f, 0.0f , 2);
				[ theSortedObjects[ index] setRotatingMatrix: _M];
				
				//sio2TransformBindMatrix( _SIO2object->_SIO2transform  );
			}
		}
	}
}

void templateMoveCamera( void *_ptr ,float _detX, float _detY, float _detZ ) {	
	
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
	
}

#pragma mark -

void backTouchHandle(void *_ptr, int type, int index, float pt_x, float pt_y) {
	vec2 pt;
	pt.x = pt_x;
	pt.y = pt_y;
	
	switch (type) {
		case 1: // Add a point
			backIsUsed[index] = TRUE;
			backTouchPoint[index] = pt;
			break;
		case 2: // Modify a point
			backTouchPoint[index] = pt;
			break;
		case 3: // Delete a point
			backIsUsed[index] = FALSE;
			break;
	}
	
}

void logToFile(NSString *logText, NSString *fileName) {
	
	NSArray			*paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString		*appFile = [[paths objectAtIndex:0] stringByAppendingPathComponent: fileName];
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


#pragma mark Help Functions for Visual Feedback:
void RenderTransparentObject ( SIO2object* obj )
{
	unsigned int j,
	n_transp = 0;
	
	void *ptr,
	**_SIO2transp = NULL;		
	SIO2object* theObject = (SIO2object* ) obj;
	
	
	if( (theObject->type & SIO2_OBJECT_TRANSPARENT ) && theObject->dst )
	{
		++n_transp;
		_SIO2transp = ( void ** ) realloc( _SIO2transp,
										  n_transp * sizeof( void * ) );
		
		_SIO2transp[ n_transp - 1 ] = theObject;
	}
	
	
	
	
	int i = 0;
	while( i != n_transp )
	{
		j = 0;
		while( j != ( n_transp - 1 ) )
		{
			SIO2object *a = ( SIO2object * )_SIO2transp[ j     ],
			*b = ( SIO2object * )_SIO2transp[ j + 1 ];
			
			if( a->dst < b->dst )
			{
				ptr = _SIO2transp[ j + 1 ];
				_SIO2transp[ j + 1 ] = _SIO2transp[ j ];
				_SIO2transp[ j     ] = ptr;
			}
			++j;
		}
		
		++i;
	}
	
	
	i = 0;
	while( i != n_transp )
	{
		sio2ObjectRender( ( SIO2object * )_SIO2transp[ i ],
						 sio2->_SIO2window,			
						 sio2->_SIO2camera,
						 !( SIO2_RENDER_TRANSPARENT_OBJECT & SIO2_RENDER_NO_MATERIAL ),
						 !( SIO2_RENDER_TRANSPARENT_OBJECT & SIO2_RENDER_NO_MATRIX ) );
		++i;
	}
	
	
	if( _SIO2transp )
	{
		free( _SIO2transp );
		_SIO2transp = NULL;
	}
	
	sio2ObjectReset();
}

void RenderSolidObject( SIO2object* obj)
{
	//if( !sio2StringCmp( obj->name, "object/fire" ))
	//{
		//obj->dst = 1.0f;
		
		//sio2DisableState( &obj->flags   , SIO2_OBJECT_INVISIBLE );
		//sio2ObjectRender( obj,
		//				  sio2->_SIO2window,
		//				  sio2->_SIO2camera,
		//				  1, SIO2_TRANSFORM_MATRIX_BIND );
		//sio2EnableState( &obj->flags   , SIO2_OBJECT_INVISIBLE );
	//}
	
	//else
	{
		obj->dst = 1.0f;
		if( ( obj->type & SIO2_OBJECT_SOLID ) && obj->dst )
		{
			sio2ObjectRender( obj,
							 sio2->_SIO2window,			
							 sio2->_SIO2camera,
							 !( SIO2_RENDER_SOLID_OBJECT & SIO2_RENDER_NO_MATERIAL ),
							 !( SIO2_RENDER_SOLID_OBJECT & SIO2_RENDER_NO_MATRIX ) );
		}
	}
	sio2ObjectReset();
}

void sortingTheObjects() 
{
	theObject* tempObject;
	SIO2camera* theCamera = ( SIO2camera* )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera" );
	double tempDistance;
	double d;
	
	for( int i=0; i< theSortedObjects.size(); i++)
	{
		tempObject   = theSortedObjects[ i ] ;
		tempDistance = fabs( theSortedObjects[ i ]._obj ->_SIO2transform->loc->x - theCamera->_SIO2transform->loc->x ); 
		
		for( int j = i+1; j< theSortedObjects.size(); j++)
		{
			d = fabs( theSortedObjects[ j ]._obj ->_SIO2transform->loc->x - theCamera->_SIO2transform->loc->x );
			if( d < tempDistance)
			{
				tempDistance = d;
				theSortedObjects[ i ]  = theSortedObjects[ j ] ;
				theSortedObjects[ j ]  = tempObject;
				tempObject = theSortedObjects[ i ] ; 
			}
		}
	}
	
}

bool checkForGroup( SIO2object* oFront, SIO2object* oBack )
{
	vec2 frontCenter, backCenter;
	
	frontCenter.x = oFront->_SIO2transform->loc->y;
	frontCenter.y = oFront->_SIO2transform->loc->z;
	backCenter.x = oBack->_SIO2transform->loc->y;
	backCenter.y = oBack->_SIO2transform->loc->z;
	
	double theDistance = fabs( pow( frontCenter.x - backCenter.x, 2 ) + pow( frontCenter.y - backCenter.y, 2 ) );
	double theDimantion = sqrt( pow( oBack->_SIO2transform->scl->x*2, 2 ) +
						   pow( oBack->_SIO2transform->scl->y*2, 2 ) + 
						   pow( oBack->_SIO2transform->scl->z*2, 2 ) );
	
	if( theDistance < theDimantion )	return true;
	else							return false;
}

#pragma mark Video Thread Functions:
void videoPlayThread( void *)
{
	/*
	 Get the video handle and keep them
	 as static variables.
	 */
	static SIO2video* fire_vid = ( SIO2video* ) sio2ResourceGetVideo( sio2->_SIO2resource, "fire" );
	
	sio2VideoQueueBuffers( fire_vid );
	

}

#pragma mark FULL SCREEN algmented functions:
void fullScreenSetup( int theTargetIndex, SIO2object* _SIO2object )
{
	theSelectedGroup.clear();
	
	theSortedObjects[ theTargetIndex ]._theLocBeforeFullScreen->x = _SIO2object->_SIO2transform->loc->x;
	theSortedObjects[ theTargetIndex ]._theLocBeforeFullScreen->y = _SIO2object->_SIO2transform->loc->y;
	theSortedObjects[ theTargetIndex ]._theLocBeforeFullScreen->z = _SIO2object->_SIO2transform->loc->z;
	
	_SIO2object->_SIO2transform->scl->x = theSortedObjects[ theTargetIndex ]._originalScl->x;
	_SIO2object->_SIO2transform->scl->y = theSortedObjects[ theTargetIndex ]._originalScl->y;
	_SIO2object->_SIO2transform->scl->z = theSortedObjects[ theTargetIndex ]._originalScl->z;
	
	_SIO2object->_SIO2transform->loc->x = camera->_SIO2transform->loc->x - 13.0;
	_SIO2object->_SIO2transform->loc->y = camera->_SIO2transform->loc->y;
	_SIO2object->_SIO2transform->loc->z = camera->_SIO2transform->loc->z;
	
	isFullScreen = YES;
	
}

#pragma mark "Minimizing" Help function:
void enlargeTheMinimizedApp( theObject* _app)
{
	//Push back all App objs displaying on the screen: 
	for( int i=0; i< theSortedObjects.size(); i++)
	{
		if( theSortedObjects[i] == _app)
		{
			for( int k = 0; k<i; k++)
			{
				theSortedObjects[k]._obj->_SIO2transform->loc->x -= 3.5;
			}
		}
	}
	
	//Show the target App obj:
	_app._obj->_SIO2transform->loc->x = 0;
	_app._obj->_SIO2transform->loc->y = _app._theLocBeforeFullScreen->y;
	_app._obj->_SIO2transform->loc->z = _app._theLocBeforeFullScreen->z;
	_app._obj->_SIO2transform->rot->x = 0;
	_app._obj->_SIO2transform->rot->y = 0;
	_app._obj->_SIO2transform->rot->z = 0;
	
	_app._isMinimized = false;

	
	//Bind the transform matrix:
	for( int i=0; i<theSortedObjects.size(); i++)
	{
		if( !theSortedObjects[i]._isMinimized )
		{
			CGFloat _M[16];
			for( int k=0; k<16; k++)
			{
				_M[k] = [ theSortedObjects[i] getRotatingMatrix ][k];
			}
			
			sio2TransformBindMatrix2( theSortedObjects[i]._obj->_SIO2transform, _M, 0.0f, 0.0f, 0.0f, 2);
			
			if( theSortedObjects[i] == _app)
			{
				sio2TransformBindMatrix2( theSortedObjects[i]._obj->_SIO2transform, _M, 0.0f, -1*_app._angleForMinimizing, 0.0f, 1);
			}
			
			[ theSortedObjects[i] setRotatingMatrix: _M];
		}
	}
	
	//Romove the Icon form theIconList:
	vector<SIO2object*>::iterator itr;
	
	for( itr = theIconList.begin(); itr != theIconList.end() ; itr++)
	{
		SIO2object* tempObj = *( itr );
		if( _app._icon == tempObj)
		{
			//Reallocate the position of the Icon:
			_app._icon->_SIO2transform->loc->z += 10;
			sio2TransformBindMatrix( _app._icon->_SIO2transform );
			theIconList.erase(itr);
			
			{ //Rearrange the rest Icons in the list: 
				for( int i=0; i< theIconList.size(); i++)
				{
					theIconList[i]->_SIO2transform->loc->y = 5 + 2.5*i;
					sio2TransformBindMatrix( theIconList[i]->_SIO2transform );
				}
			}
			

			break;
		}
	}
	
	//Ending Process:
	sortingTheObjects();
	
}

