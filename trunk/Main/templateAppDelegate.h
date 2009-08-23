//
//  templateAppDelegate.h
//  template
//
//  Created by SIO2 Interactive on 8/22/08.
//  Copyright SIO2 Interactive 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Picker.h"
#import "BrowserViewController.h"
#import "TCPServer.h"

@class EAGLView;
//@class Multitouch;

@interface templateAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate, BrowserViewControllerDelegate, TCPServerDelegate,
                                           UIAccelerometerDelegate> {
	IBOutlet UIWindow *_window;
	IBOutlet EAGLView *glView;
	Picker*				_picker;
	TCPServer*			_server;
	NSInputStream*		_inStream;
	NSOutputStream*		_outStream;
	BOOL				_inReady;
	BOOL				_outReady;
	IBOutlet UIButton  *logButton;
	IBOutlet UITextField *filename;
			   
	int myNumber;

}

//- (void) transmitTouch:(CGPoint)point andNum:(int)num andType:(int)type;
//- (void) transmitTouch: (CGPoint)point andNum: (int)num andType: (int)type;
//- (void) transmitTouchAtSameTime: (int*)touchIdx andCount: (int)count;

- (IBAction) showLogButton; 

@property (nonatomic, retain) UIWindow *_window;
@property (nonatomic, retain) EAGLView *glView;
@property (nonatomic, retain) IBOutlet UIButton  *logButton;
@property (nonatomic, retain) IBOutlet UITextField *filename;

//- (void) send:(const uint32_t)message;

@end

