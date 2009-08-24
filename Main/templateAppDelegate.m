//
//  templateAppDelegate.m
//  template
//
//  Created by SIO2 Interactive on 8/22/08.
//  Copyright SIO2 Interactive 2008. All rights reserved.
//

#import "templateAppDelegate.h"
#import "EAGLView.h"

#define kGameIdentifier		@"witap"
@interface templateAppDelegate ()
- (void) setup;
- (void) presentPicker:(NSString*)name;
@end

@implementation templateAppDelegate
@synthesize _window;
@synthesize glView;
@synthesize filename;
@synthesize logButton;

- (void)applicationDidFinishLaunching:(UIApplication *)application {

	glView.animationInterval = 1.0 / 60.0;
	[glView startAnimation];
	[glView setTag:1];
	

	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
		
	// Flip the simulator to the right
	[[UIApplication sharedApplication] setStatusBarOrientation: UIInterfaceOrientationLandscapeRight animated: NO];

    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:( 1.0f / 30.0f )];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];	
	

	[self setup];
}

//-------------------------------------------------------------------- FUNCTIONS INCLUDE FROM BACK-TOUCH

- (void) _showAlert:(NSString*)title
{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void) setup {
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream release];
	_inStream = nil;
	_inReady  = NO;
	
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream release];
	_outStream = nil;
	_outReady = NO;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		NSLog(@"Failed creating server: %@", error);
		[self _showAlert:@"Failed creating server"];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}
	
	[self presentPicker:nil];
}

// Make sure to let the user know what name is being used for Bonjour advertisement.
// This way, other players can browse for and connect to this game.
// Note that this may be called while the alert is already being displayed, as
// Bonjour may detect a name conflict and rename dynamically.
- (void) presentPicker:(NSString*)name {
	if (!_picker) {
		_picker = [[Picker alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] type:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier]];
		_picker.delegate = self;
	}
	
	_picker.gameName = name;
	
	if (!_picker.superview) {
		[_window addSubview:_picker];
	}
}

- (void) destroyPicker {
	[_picker removeFromSuperview];
	[_picker release];
	_picker = nil;
}

// If we display an error or an alert that the remote disconnected, handle dismissal and return to setup
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup];
}

/*
- (void) send:(const uint32_t)message   // 真實送資料出去的函式
{
	if (_outStream && [_outStream hasSpaceAvailable])
		if([_outStream write:(const uint8_t *)&message maxLength:sizeof(const uint32_t)] == -1)
			[self _showAlert:@"Failed sending data to peer"];
}

- (void) transmitTouch:(CGPoint)point andNum:(int)num andType:(int)type{
	
	uint32_t data = ((uint32_t)type << 28)
	+ ((uint32_t)point.x << 16)
	+ ((uint32_t)num << 12)  
	+ (uint32_t)point.y;
	[self send:data];
}

- (void) transmitTouchAtSameTime: (int*)touchIdx andCount: (int)count {
	uint32_t data = ((uint32_t)4 << 28)
	+ ((uint32_t)count << 24)
	+ ((uint32_t)touchIdx[0] << 20)
	+ ((uint32_t)touchIdx[1] << 16)
	+ ((uint32_t)touchIdx[2] << 12)
	+ ((uint32_t)touchIdx[3] << 8)
	+ ((uint32_t)touchIdx[4] << 4);
	[self send:data];
}
*/

- (void) openStreams
{
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)netService
{
	if (!netService) {
		[self setup];
		return;
	}
	
	if (![netService getInputStream:&_inStream outputStream:&_outStream]) {
		[self _showAlert:@"Failed connecting to server"];
		return;
	}
	
	[self openStreams];
}
//--------------------------------------------------------------------


- (void)applicationWillResignActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 5.0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 60.0;
}

- (void)dealloc {
	[_window release];
	[glView release];
	[super dealloc];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	sio2->_SIO2window->accel->x = acceleration.x * 0.1f + sio2->_SIO2window->accel->x * 0.9f;
	sio2->_SIO2window->accel->y = acceleration.y * 0.1f + sio2->_SIO2window->accel->y * 0.9f;
	sio2->_SIO2window->accel->z = acceleration.z * 0.1f + sio2->_SIO2window->accel->z * 0.9f;	
	sio2ResourceDispatchEvents( sio2->_SIO2resource,
								sio2->_SIO2window,
								SIO2_WINDOW_ACCELEROMETER,
								SIO2_WINDOW_TAP_NONE );
}

- (IBAction) showLogButton
{
	logButton.hidden = NO;
	filename.hidden = NO;
	[filename becomeFirstResponder];
}

@end

//---------------------------------OTHER DELEGATES
@implementation templateAppDelegate (NSStreamDelegate)

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
	//UIAlertView* alertView;
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			[self destroyPicker];
			
			[_server release];
			_server = nil;
			
			if (stream == _inStream)
				_inReady = YES;
			else
				_outReady = YES;
			/*
			 if (_inReady && _outReady) {
			 alertView = [[UIAlertView alloc] initWithTitle:@"Game started!" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			 [alertView show];
			 [alertView release];
			 }
			 */ 
			break;
		}
		case  NSStreamEventHasBytesAvailable:
		/* {
			if (stream == _inStream) {
				uint8_t buff[4];
				bzero(buff, sizeof(buff));
				unsigned int len = 0;
				len = [_inStream read:buff maxLength:sizeof(uint32_t)];
				
				if(!len) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self _showAlert:@"Failed reading data from peer"];
				}
				else {
					uint16_t* tmp;
					tmp = (uint16_t *)buff;
					uint16_t y = *tmp;
					tmp = (uint16_t *)&buff[2];
					uint16_t x = *tmp;
					
					int type = x >> 12;
					int num  = y >> 12;
					CGFloat tmp_x = 320 - (float) (x & 0x0FFF);
					CGFloat tmp_y = (float) (y & 0x0FFF);
					CGPoint point = CGPointMake(tmp_x, tmp_y);
					
					// TODO: Change here to the EGALview Function!! --------------------------------------
					[(EAGLView*)[_window viewWithTag:1] backTouch:point andNum:num andType:type];
					//-------------------------------------------------------------------------------------
				}
				
			}

			break;
		} */
		{
			if (stream == _inStream) {
				uint8_t buff[4];
				bzero(buff, sizeof(buff));
				unsigned int len = 0;
				len = [_inStream read:buff maxLength:sizeof(uint32_t)];
				
				if(!len) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self _showAlert:@"Failed reading data from peer"];
				}
				else {
					uint16_t* tmp;
					tmp = (uint16_t *)buff;
					uint16_t y = *tmp;
					tmp = (uint16_t *)&buff[2];
					uint16_t x = *tmp;
					
					int type = x >> 12;
					
					if (type == 4) {     // 同時有兩個以上手指觸發touch事件
						int count = (int) (x & 0x0F00) >> 8;
						int touchIdx[5];
						
						touchIdx[0] = (int) (x & 0x00F0) >> 4;
						touchIdx[1] = (int) (x & 0x000F) ;
						touchIdx[2] = (int) (y & 0xF000) >> 12;
						touchIdx[3] = (int) (y & 0x0F00) >> 8;
						touchIdx[4] = (int) (y & 0x00F0) >> 4;
						
						[(EAGLView*)[_window viewWithTag:1] setTouchAtSameTime: count andFront: NO];	
					}
					else {
						int num  = y >> 12;
						CGFloat tmp_x = 320 - (float) (x & 0x0FFF);
						CGFloat tmp_y = (float) (y & 0x0FFF);
						CGPoint point = CGPointMake(tmp_x, tmp_y);
						[(EAGLView*)[_window viewWithTag:1] backTouch:point andNum:num andType:type];					
					}
				}
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			
			UIAlertView*			alertView;
			
			NSLog(@"%s", _cmd);
			
			alertView = [[UIAlertView alloc] initWithTitle:@"Peer Disconnected!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];
			
			break;
		}
	}
}

@end

@implementation templateAppDelegate (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string {
	NSLog(@"%s", _cmd);
	[self presentPicker:string];
}




- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	if (_inStream || _outStream || server != _server)
		return;
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

@end
