/*

File: AppController.m
Abstract: UIApplication's delegate class, the central controller of the
application.

Version: 1.5

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import "AppController.h"
#import "Picker.h"

//CONSTANTS:

#define kNumPads			9

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kGameIdentifier		@"witap"

@interface HelloController : UIViewController
@end

@implementation HelloController
- (void)loadView
{
	printf("@load View\n");
	Multitouch *contentView = [[Multitouch alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[contentView init];
	[contentView setTag:1];
	self.view = contentView;
    [contentView release];
	printf("end loadView\n");//debug
} // initialize Multitouch + change view
@end

//INTERFACES:

@interface AppController ()
- (void) setup;
- (void) presentPicker:(NSString*)name;
@end

//CLASS IMPLEMENTATIONS:

@implementation AppController

- (void) _showAlert:(NSString*)title
{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	//Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	HelloController *hello = [[HelloController alloc] init];
	[_window addSubview:hello.view];	
	//Show the window
	[_window makeKeyAndVisible];
	
	//Create and advertise a new game and discover other availble games
	[self setup];
}

- (void) dealloc
{	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_inStream release];

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_outStream release];

	[_server release];
	
	[_picker release];
	
	[_window release];
	
	[super dealloc];
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

@end

@implementation AppController (NSStreamDelegate)

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
					int num  = y >> 12;
					CGFloat tmp_x = 320 - (float) (x & 0x0FFF);
					CGFloat tmp_y = (float) (y & 0x0FFF);
					CGPoint point = CGPointMake(tmp_x, tmp_y);
					[(Multitouch*)[_window viewWithTag:1] backTouch:point andNum:num andType:type];
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

@implementation AppController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
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
