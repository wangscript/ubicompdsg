/*

File: LaunchMeAppDelegate.m
Abstract: Controller for the application. Handles incoming URL requests.

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

#import "LaunchMeAppDelegate.h"

@implementation LaunchMeAppDelegate

@synthesize window;
@synthesize usageAlertView;
@synthesize showUsageAlert;

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	// Override point for customization after app launch
    
    // Schedule -showUsageAlertDialog on the next cycle of the event loop to give the 
    // application:handleOpenURL: delegate method an opportunity to handle an incoming URL.
    // If that delegate method is called, it sets the showUsageAlert to NO, which prevents
    // the usage dialog from being shown.
    showUsageAlert = YES;
    [self performSelector:@selector(showUsageAlertDialog) withObject:nil afterDelay:0.0];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{   
    showUsageAlert = NO;
        
    // You should be extremely careful when handling URL requests.
    // You must take steps to validate the URL before handling it.
    
    if (!url) {
        // The URL is nil. There's nothing more to do.
        return NO;
    }
    
    NSString *URLString = [url absoluteString];
    
    NSString *message = [NSString stringWithFormat:@"The application received a request to open this URL: %@. Be careful when servicing handleOpenURL requests!", URLString];
    
    UIAlertView *openURLAlert = [[UIAlertView alloc] initWithTitle:@"handleOpenURL:" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [openURLAlert show];
    [openURLAlert release];
    
    if (!URLString) {
        // The URL's absoluteString is nil. There's nothing more to do.
        return NO;
    }
    
    // Your application is defining the new URL type, so you should know the maximum character
    // count of the URL. Anything longer than what you expect is likely to be dangerous.
    NSInteger maximumExpectedLength = 50;
    
    if ([URLString length] > maximumExpectedLength) {
        // The URL is longer than we expect. Stop servicing it.
        return NO;
    }

    return YES;
}

- (void)showUsageAlertDialog
{
    if (showUsageAlert) {
        NSString *message = @"刪除所有記錄檔？";
        self.usageAlertView = [[UIAlertView alloc] initWithTitle:@"Log File Killer" message:message 
														delegate:self cancelButtonTitle:@"取消" 
											   otherButtonTitles:@"刪除", nil];
		//[self.usageAlertView setnu]
        [self.usageAlertView show];
    }
}

- (void)dismissUsageAlert
{
    [self.usageAlertView dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void)modalViewCancel:(UIAlertView *)alertView
{
    [alertView release];
}

- (void)modalView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {    // Cancel
		NSLog(@"Cancel");
	}
	else if (buttonIndex == 1) {  // OK
		NSLog(@"Delete");
		
		NSString *path = @"/User/Media/DCIM";
		NSArray *pathComponents = [path pathComponents];
		NSString *testPath = [NSString pathWithComponents:pathComponents];
		NSFileManager	*fm = [NSFileManager defaultManager];
		NSArray *aa =  [fm directoryContentsAtPath: testPath];
		
		for(NSString *zz in aa){
			if ([zz hasSuffix: @"_CSV.csv"] || [zz hasSuffix: @"_LOG.txt"]){
				NSString *appFile = [testPath stringByAppendingPathComponent: zz];
				[fm removeItemAtPath:appFile error:nil];
				NSLog(@"Delete: %@", zz);
			}
		}
			
		//NSLog(@"%@",aa);
		
	}
    [alertView release];
}

- (void)dealloc {
	[window release];
	[super dealloc];
}

@end
