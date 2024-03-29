/*

[ EULA: Revision date: 2009/03/22 ]

SIO2 Engine 3D Game for iPhone & iPod Touch :: Free Edition

Copyright (C) 2009 SIO2 Interactive http://sio2interactive.com

This software is provided 'as-is', without any express or implied warranty.

In no event will the authors be held liable for any damages arising from the use
of this software.

Permission is granted to anyone to use this software for any purpose, including
free or commercial applications, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim
that you wrote the original software. 

If you are using the "Free Edition" of this software in a product (either free
or commercial), you are required to display a full-screen "Powered by SIO2 engine"
splash screen logo in the start up sequence of any product created and released
with the SIO2 Engine.

This screen shall be visible for no less than two (2) seconds, using one (1) of
the two (2) files provided with the SIO2 SDK:

(a) "/SIO2_SDK/src/poweredby_p.jpg" for portrait

(b) "/SIO2_SDK/src/poweredby_l.jpg" for landscape.

2. Altered source versions must be plainly marked as such (even for internal use),
and must not be misrepresented as being the original software. You are also invited
to post any modifications done to the SIO2 source, at the following email
address: sio2interactive@gmail.com, for review and possible addition to the SIO2
source tree to make them available to the community and to make SIO2 a better
software. But it is not required to do so.

3. This notice may not be removed or altered from any source distribution.

4. If your product using SIO2 Engine "Free Edition" is made available to the
public ( either in a free or commercial form ) you are required to let us know
by email (sio2interactive@gmail.com) the following information:

- The title of your product

- A short description of your product

- A valid URL and screenshot(s) of the product in order for us to put it on our
website (http://sio2interactive.com/GAMES.html) in order to help you promote
your creation(s) as well as promoting the SIO2 project.

If you have any questions or want more information concerning this agreement
please send us an email at: sio2interactive@gmail.com

SIO2 Engine is using other external library and source packages and their
respective license(s), as well as this one, can be found in the 
"/SIO2_SDK/src/LICENSE/" directory, please review all the licenses before
making your product available.




[ EULA: Revision date: 2009/03/23 ]

SIO2 Engine 3D Game for iPhone & iPod Touch :: Indie Edition

Copyright (C) 2009 SIO2 Interactive http://sio2interactive.com

This software is provided 'as-is', without any express or implied warranty.

In no event will the authors be held liable for any damages arising from the use
of this software.

Permission is granted to anyone to use this software for free or commercial applications,
subject to the following restrictions:

1. By using the "SIO2 Indie Edition" you are required to use and include the "sio2.cert"
certificate within your application on a game basis. The certificate will be send to you to
the email that you provide within the purchase form in the next two (2) working days. Certificate
is restricted on a per application basis, you CANNOT reuse the certificate for multiple game
production.

2. By using the "SIO2 Indie Edition" you are entitled of a life time free upgrade to any
subsequent SIO2 versions on a game basis prior to the initial purchase date. Every time
a new version is made available you will receive notification by email within two (2) 
working days after its official release.

3. You must use an independent certificate for every game that you release, either free or
commercial.

4. By using the "SIO2 Indie Edition" you are NOT required to use any splash screen, or
mention of any kind of SIO2 Engine or SIO2 Interactive within your application.

5. By using the "SIO2 Indie Edition" you are entitled to receive customer support and
customer service within working hours (either on IM or by email at sio2interactive@gmail.com).
Every requests will be answered within 48 hours or two (2) working days.

6. You are required to NOT clear the console output and do not override the system log in
order to display at any time on the console prompt the information that your "sio2.cert"
hold, such as your "Game Studio" and "Game Title" as well as your unique certificate key
bundle within your ".app".

7. If your product using SIO2 Engine "Indie Edition" is made available to the public
( either in a free or commercial form ) you are invited to let us know by email
(sio2interactive@gmail.com) the following information:

- The title of your product

- A short description of your product

- A valid URL and screenshot(s) of the product in order for us to put it on our
website (http://sio2interactive.com/GAMES.html) in order to help you promote
your creation(s) as well as promoting the SIO2 project.

But it is NOT required to do so.

If you have any questions or want more information concerning this agreement
please send us an email at: sio2interactive@gmail.com

SIO2 Engine is using other external library and source packages and their
respective license(s), as well as this one, can be found in the 
"/SIO2_SDK/src/LICENSE/" directory, please review all the licenses before
making your product available.

*/


#ifndef SIO2_WINDOW_H
#define SIO2_WINDOW_H

#define SIO2_WINDOW_MAX_TOUCH 5

typedef enum
{
	SIO2_WINDOW_NONE = 0,
	SIO2_WINDOW_TAP,
	SIO2_WINDOW_TOUCH_MOVE,
	SIO2_WINDOW_ACCELEROMETER,
	
	//added by danielbas{
	my_WINDOW_CHANGE_OBJ_SCALE,  
    my_WINDOW_ROTATE_OBJ,
	my_WINDOW_MOVE_OBJ,
	my_WINDOW_MOVE_CAMERA,
	my_WINDOW_BACK_HANDLE
	//} added by danielbas

} SIO2_WINDOW_EVENT;


typedef enum
{
	SIO2_WINDOW_TAP_NONE = 0,
	SIO2_WINDOW_TAP_UP,
	SIO2_WINDOW_TAP_DOWN

} SIO2_WINDOW_TAP_STATE;


typedef void( SIO2windowrender( void ) );

typedef void( SIO2windowtap( void *, unsigned char ) );

typedef void( SIO2windowtouchmove( void * ) );

//added by danielbas{
typedef void( SIO2windowChangeObjScl( void * , float) );

typedef void( SIO2windowRotateObj( void * , int , int) ); 

typedef void( SIO2windowMoveObj (void*, float, float, float)); 

typedef void( SIO2windowMoveCamera (void*, float, float, float)); 

typedef void( SIO2windowBackHandle (void *, int , int, float, float));

//} added by dnaielbas

typedef void( SIO2windowaccelerometer( void * ) );

typedef void( SIO2windowshutdown( void ) );


typedef struct
{
	int							n_tap;
	
	int							n_touch;
	vec2						**touch;
	
	vec2						*loc;
	vec2						*scl;
	
	vec3						*accel;
	float						accel_smooth;
	
	int							*mat_viewport;

	unsigned int				curr_time;
	unsigned int				last_sync;
	
	float						fra;
	float						fps;

	float						d_time;
	float						sync_time;
	
	float						volume;
	float						fx_volume;

	SIO2windowrender			*_SIO2windowrender;
	SIO2windowtap				*_SIO2windowtap;
	SIO2windowtouchmove			*_SIO2windowtouchmove;
	SIO2windowaccelerometer		*_SIO2windowaccelerometer;
	SIO2windowshutdown			*_SIO2windowshutdown;
	//added by danielbas{
	SIO2windowChangeObjScl      *_SIO2windowChangeObjScl;
	SIO2windowRotateObj         *_SIO2windowRotateObj;  
	SIO2windowMoveObj           *_SIO2windowMoveObj;
	SIO2windowMoveCamera        *_SIO2windowMoveCamera;
	SIO2windowBackHandle		*_SIO2windowBackHandle;
	//} added by danielbas
	
	void						*userdata;

} SIO2window;


SIO2window *sio2WindowInit( void );

SIO2window *sio2WindowFree( SIO2window * );

void sio2WindowShutdown( SIO2window	*, SIO2windowshutdown * );

void sio2WindowGetViewportMatrix( SIO2window * );

void sio2WindowUpdateViewport( SIO2window *, int, int, int, int );

void sio2WindowSwapBuffers( SIO2window * );

void sio2WindowDebugTouch( SIO2window * );

void sio2WindowEnter2D( SIO2window *, float, float );

void sio2WindowLeave2D( void );

void sio2WindowEnterLandscape3D( void );

void sio2WindowLeaveLandscape3D( void );

void sio2WindowEnterLandscape2D( SIO2window * );

void sio2WindowLeaveLandscape2D( SIO2window * );

void sio2WindowSetAccelerometerSensitivity( SIO2window *, float );


void sio2WindowAddTouch( SIO2window *, float, float );

void sio2WindowResetTouch( SIO2window * );

#endif
