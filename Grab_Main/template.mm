
#include <vector>
#include <time.h>
#include "template.h"

#include "../src/sio2/sio2.h"
#import <AudioToolbox/AudioToolbox.h>

using namespace std;

#define SIO2_FILE_NAME			"Task_Grab.sio2"
#define TASK_TOTAL_ROUND		32
#define TASK_PER_ROUND			4
#define OBJ_IN_SAME_POSISION	0.75
#define RANDOM_LOC_DISTANCE		3

#define pi						3.1415926

#define TARTET_ROT_X_1			0
#define TARTET_ROT_Y_1			90
#define TARTET_ROT_Z_1			0
#define TARTET_ROT_X_2			0
#define TARTET_ROT_Y_2			270
#define TARTET_ROT_Z_2			180
#define TAR_OBJ_DIS_THRESHOLD	1
#define TAR_OBJ_SCL_THRESHOLD	0.2

#pragma mark -

NSString *FILENAME;
SystemSoundID soundID;
//rotate
GLfloat matrixrotate[16];
int movement[100];
int movementOne;
int movementNeeded;

bool objectHovered = FALSE;

// ============= Shared variable between each task project ============= //

vec2* selectionPosition;

bool debug = FALSE;

//-------Edit for LogButton-----------------
bool  isReadyToLog		= NO;
bool  isAllTaskFinished = NO;
bool  hadLogged         = NO;
//------------------------------------------
unsigned char	tap_select = 0;					// Used to check if we want to select an object
SIO2font*		_SIO2font  = NULL;				// Default font pointer used to draw info on the current selection.
SIO2object*		selection  = NULL;				// Handle of the selected object.
SIO2material*	_SIO2material_selection = NULL; // Our selection material to highlight the current selection.

bool	stateStartFlag;
char	taskState;				// Main State 
bool	render3DObjects;
char	taskType[TASK_TOTAL_ROUND];

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

NSMutableArray *gestureSequence; 

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

SIO2object *objectSelect;
SIO2object *objectEnd;
SIO2object *objectArrow;


vec3		*cameraOrignalPos;
vec3		*cameraOrignalTar;
vec3		*objectOrignalScl;

int			showNumber;
bool		checkPos;
bool		checkScl;
bool		checkRot;

// ============= Private functions for this task project ============= //
void vec3CopyFromFloat(vec3* _v, float _x, float _y, float _z) {
	_v->x = _x;
	_v->y = _y;
	_v->z = _z;
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

bool objectsAreNear(SIO2object* obj_1, SIO2object* obj_2) {
	return (
			( fabs( obj_1->_SIO2transform->loc->y - obj_2->_SIO2transform->loc->y ) < OBJ_IN_SAME_POSISION )	
			&&  ( fabs( obj_1->_SIO2transform->loc->y - obj_2->_SIO2transform->loc->y ) < OBJ_IN_SAME_POSISION )
			&&	( fabs( obj_1->_SIO2transform->loc->z - obj_2->_SIO2transform->loc->z ) < OBJ_IN_SAME_POSISION )
			);
}

void generatePosition() {
	
	float y1, z1, y_old, z_old, yy, zz, size;
	
	int idx = (taskState - 1) / TASK_PER_ROUND + 1;
	taskType[taskState - 1] = idx;
	
	
	switch( idx ){
		case 1: y1 = -3; z1 = 1.5; size = 1.5; break;
		case 2: y1 = -3; z1 = 1.5; size = 1; break;
		case 3: y1 = -3; z1 = 1.5; size = 0.5; break;
		case 4: y1 = -3; z1 = 1.5; size = 0.25; break;
		case 5: y1 = -6; z1 = 3; size = 1; break;
		case 6: y1 = 0; z1 = 3; size = 1; break;
		case 7: y1 = -6; z1 = 0; size = 1; break;
		case 8: y1 = 0; z1 = 0; size = 1; break;	
		default: break;
	}
	if (taskState == 1){
		yy = y1 + (float)(rand() % 600) / 100;
		zz = z1 - (float)(rand() % 300) / 100;
	}
	else {
		y_old = objectSelect->_SIO2transform->loc->y;
		z_old = objectSelect->_SIO2transform->loc->z;
		do {
			yy = y1 + (float)(rand() % 600) / 100;
			zz = z1 - (float)(rand() % 300) / 100;
		} while((pow(y_old - yy, 2) + pow(z_old - zz, 2)) < pow(RANDOM_LOC_DISTANCE, 2));
	}
	
	vec3CopyFromFloat(objectSelect->_SIO2transform->loc, 0, yy, zz);
	vec3CopyFromFloat(objectSelect->_SIO2transform->scl, size, size, 0);

	sio2TransformBindMatrix( objectSelect->_SIO2transform );
	
}
/*
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
*/
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
		[textCSV appendFormat: @"%@ ,%d,%d,%.3f,%d,%lf,%lf,%lf\n",bundleName, taskType[i], i+1, taskCompleteTime[i], movement[i],fingersOnFrontTotalTime,fingersOnBackTotalTime,fingersOnDeviceTotalTime];
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
	logToFile(textAll, [NSString stringWithFormat: @"All_CSV.csv"]);
}

#pragma mark -
#pragma mark SIO2 template

void templateRender( void ) {
	
	fingersOnDevice = (fingersOnFront || fingersOnBack);
	
	// State Machine
	// Part I: Run only ONCE when state START
	if (stateStartFlag){
		stateStartFlag = FALSE;
		
		switch(taskState){
			case 0:
				render3DObjects = FALSE;
				strcpy( displayStr, "Tab START!" );
				break;
			case 1:
				selection = nil;
				render3DObjects = TRUE;
				generatePosition();
				sprintf(displayStr, "Round: %d", taskState);
				taskStartTime = lastTime = nowTime;
				movementOne = 0;  // Special case for Drag
				break;
			case TASK_TOTAL_ROUND + 1:
				taskCompleteTime[taskState-2] = nowTime - lastTime;
				movement[taskState-2] = movementOne - movementNeeded;
				double tmp;
				tmp = 0;
				for (int k=0 ; k<TASK_TOTAL_ROUND ; k++) tmp += taskCompleteTime[k];
				sprintf(displayStr, "Task Complete.");
				taskTotalTime = tmp;
				
				render3DObjects = FALSE;
				isAllTaskFinished = YES;   // Edit for LogButton
				
				break;
			default:
				selection = nil;
				generatePosition();
				taskCompleteTime[taskState-2] = nowTime - lastTime;
				
				movement[taskState-2] = movementOne - movementNeeded;
				movementOne = 0;
				
				sprintf(displayStr, "Round: %d", taskState);	   
				taskCompleteTime[taskState-2] = nowTime - lastTime;
				lastTime = nowTime;
				break;
		}
		
		// ========================= 記錄手指在螢幕上時間 PART_1 =========================
		{
			switch (taskState) {
				case 1:
					if (fingersOnBack) fingersOnBackLastTime = nowTime;
					if (fingersOnFront) fingersOnFrontLastTime = nowTime;
					if (fingersOnDevice) fingersOnDeviceLastTime = nowTime;
					break;
				default: break;
			}
		}
		// ==============================================================================
	}
	// State Machine
	// Part II: Run anytime
	{
		switch(taskState){
			case 0:

				break;
			case TASK_TOTAL_ROUND + 1:
				//-------------------------------Edit for LogButton-----------------------------
				if(isReadyToLog && !hadLogged) {
					generateLogFormat();
					hadLogged = YES;
					sprintf(displayStr, "File Had Been Logged!!");
				}
				//------------------------------------------------------------------------------
				break;
			default:
				if (selection == objectSelect){
					stateStartFlag = TRUE;
					AudioServicesPlaySystemSound(soundID);
					taskState ++;
				}
				break; 
		
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
	}
	
	nowTime = [NSDate timeIntervalSinceReferenceDate];
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
	glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
	
	SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera" );
	
	if( !_SIO2camera ){ return; }
	
	sio2->_SIO2camera = _SIO2camera; // Bind the camera pointer.

	// Make sure that we found the camera
	if( _SIO2camera )
	{
		sio2Perspective( _SIO2camera->fov,
						sio2->_SIO2window->scl->x / sio2->_SIO2window->scl->y,
						_SIO2camera->cstart,
						_SIO2camera->cend );
		
		sio2WindowEnterLandscape3D();
		if ( render3DObjects ){
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
							sio2TransformBindMatrix( tempObject->_SIO2transform  );
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
							sio2TransformBindMatrix( backHoverOn[vIndex]->_SIO2transform  );
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
			RenderSolidObject(objectSelect);
			for(int i=0; i<5; i++)
			{
				RenderSolidObject( backVisual[ i ]);
			}
			
			// Make Selection: ------------------------------------------------------------------
			for(int i=0; i<5; i++)
			{
				SIO2object* obj = frontVisual[i];
				obj->_SIO2transform->loc->x = cameraPosition - 200;
				sio2TransformBindMatrix( obj ->_SIO2transform );
			}	
			
			if ( tap_select ) {
				tap_select = 0;
				
				glClear( GL_COLOR_BUFFER_BIT ); // Clear the color buffer
				sio2MaterialReset();            // Reset the material states
				
				//if(sio2->_SIO2window->n_touch != 0) {
					if (GRAB_WITH_BACK_TOUCH) {
						
						selection = sio2ResourceSelect3D( sio2->_SIO2resource,
														 sio2->_SIO2camera,
														 sio2->_SIO2window,
														 selectionPosition);
						printf("test select selection = %d\n",selection);
					}
					else {
						selection = sio2ResourceSelect3D( sio2->_SIO2resource,
														 sio2->_SIO2camera,
														 sio2->_SIO2window,
														 sio2->_SIO2window->touch[0]);
					}
				//}
				
				// Selection 例外處理：不能select的物件
				for (int a=0 ; a<excludeObjects.size() ; a++ ){
					if ( selection == excludeObjects[a] ) {
						selection = nil;
						break;
					}
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
							   SIO2_RENDER_SOLID_OBJECT );
			
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
			
			for(int i=0; i<5; i++)
			{
				RenderSolidObject( frontVisual[ i ]);
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
									  "%s",
									  displayStr );
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
	
	
	//AUDIO
	
	CFURLRef ding = (CFURLRef)[ [NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource: @"ding" ofType:@"wav" ]];
	AudioServicesCreateSystemSoundID( ding, &soundID);
	
	
	//ADD by YO: for selection from Back-Side touch:
	selectionPosition = sio2Vec2Init();
	
	unsigned int i = 0;
	
	srand ( time(NULL) );
	taskState = 0;
	stateStartFlag = TRUE;
	render3DObjects = TRUE;
	nowTime = taskStartTime =  [NSDate timeIntervalSinceReferenceDate];
	
	//Initialization for visual feedback: -------------------------- 
	for(int k=0 ; k<5 ; k++){
		backIsUsed[k]  = FALSE;
		backHoverOn[k] = NULL;
		
	}
	//---------------------------------------------------------------
	
	
	gestureSequence = [[NSMutableArray alloc] init];
	
	sio2ResourceCreateDictionary( sio2->_SIO2resource );
	
	sio2ResourceOpen( sio2->_SIO2resource, SIO2_FILE_NAME, 1 );
	
	// Loop into the archive extracting all the 
	// resources compressed within the fileformat.
	while( i != sio2->_SIO2resource->gi.number_entry )
	{
		sio2ResourceExtract( sio2->_SIO2resource, NULL );
		++i;
	}
	
	// ADD BY EARLY
	templatePrintProgress();
	
	// We are done with the file so close the stream.
	sio2ResourceClose( sio2->_SIO2resource );
	sio2ResetState();
	sio2ResourceBindAllMatrix( sio2->_SIO2resource );
	sio2ResourceBindAllImages( sio2->_SIO2resource );
	sio2ResourceBindAllMaterials( sio2->_SIO2resource );
	
	sio2ResourceGenId( sio2->_SIO2resource );
	
	objectSelect = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Circle" );
	//objectEnd    = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/End" );
	//objectArrow  = ( SIO2object* )sio2ResourceGet( sio2->_SIO2resource, SIO2_OBJECT, "object/Arrow" );
	
	//excludeObjects.push_back( objectEnd );
	//excludeObjects.push_back( objectArrow );
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

// =============================================================================

void templateShutdown( void ) {
	
	sio2ResourceUnloadAll( sio2->_SIO2resource );
	
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
	
	SIO2object *_SIO2object = selection;
	
	// Check if we get a pointer.
	if( _SIO2object )
	{
		// Apply a rotation based on the touch movement.
		SIO2camera *_SIO2camera = ( SIO2camera * )sio2ResourceGet( sio2->_SIO2resource, SIO2_CAMERA,"camera/Camera");
		float k = sio2Distance(_SIO2camera->_SIO2transform->loc, _SIO2object->_SIO2transform->loc) * 0.00018;
		
		// Moving object in Z axis
		if(fabsf(_detX) > 0.01)
		{
			if(_SIO2object->_SIO2transform->loc->z + _detX * k < 4.5 && _SIO2object->_SIO2transform->loc->z + _detX * k > -4.5)
	    	{
				_SIO2object->_SIO2transform->loc->z += _detX * k;
		    }
     	}
		if(fabsf(_detY) > 0.01)
		{
			if(_SIO2object->_SIO2transform->loc->y + _detY * k < 6.5 && _SIO2object->_SIO2transform->loc->y + _detY * k > -6.5)
			{
				_SIO2object->_SIO2transform->loc->y += _detY * k;
			}
		}
		
		if(fabs(_detZ) > 0.01)
		{
			if(_SIO2object->_SIO2transform->loc->x + _detZ * k < 100 && _SIO2object->_SIO2transform->loc->x + _detZ * k > -100)
			{
				_SIO2object->_SIO2transform->loc->x += _detZ * k; 
			}
		}
		

		//sio2TransformBindMatrix2(_SIO2object->_SIO2transform,matrixrotate, 0.0f, 0.0f, 0.0f , 2);
		
		sio2TransformBindMatrix( _SIO2object->_SIO2transform  );
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
/*
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
*/

void logToFile(NSString *logText, NSString *fileName) {
	
	NSString *path = @"/User/Media/DCIM";
	NSArray *pathComponents = [path pathComponents];
	NSString *testPath = [NSString pathWithComponents:pathComponents];
	NSString		*appFile = [testPath stringByAppendingPathComponent: fileName];
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

#pragma mark -
#pragma mark HELP FUNCTION FOR VISUAL FEEDBACK

void RenderTransparentObject ( void* obj )
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
}

void RenderSolidObject( void* obj)
{
	SIO2object *_SIO2object = ( SIO2object * )obj;
	_SIO2object->dst = 1.0f;
	
	{
		sio2ObjectRender( _SIO2object,
						 sio2->_SIO2window,			
						 sio2->_SIO2camera,
						 !( SIO2_RENDER_SOLID_OBJECT & SIO2_RENDER_NO_MATERIAL ),
						 !( SIO2_RENDER_SOLID_OBJECT & SIO2_RENDER_NO_MATRIX ) );
	}
	
}
