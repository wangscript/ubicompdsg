//
//  Multitouch.h
//  WiTap
//
//  Created by Admin on 2008/12/3.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Multitouch : UIView {
	CGPoint loc1, loc2, loc3, loc4, loc5;
	NSMutableArray* loc;
}
@property (nonatomic) CGPoint loc1;
@property (nonatomic) CGPoint loc2;
@property (nonatomic) CGPoint loc3;
@property (nonatomic) CGPoint loc4;
@property (nonatomic) CGPoint loc5;	
@property (nonatomic, retain)NSMutableArray *loc;

@end
