//
//  UIView+DTDebug.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 2/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Methods useful for debugging problems with UIView instances.
 */

@interface UIView (DTDebug)

/**
 Toggles on/off main queue checking on several methods of UIView.
 
 Currently the following methods are swizzeled and checked:
 
 - setNeedsDisplay
 - setNeedsDisplayInRect:
 - setNeedsLayout
 
 Those are triggered by a variety of methods in UIView, e.g. setBackgroundColor and thus it is not necessary to swizzle all of them.
 */
+ (void)toggleViewMainQueueChecking;

/**
 Method that gets called if one of the important methods of UIView is not being called on a main queue. 
 
 Toggle this on/off with <toggleViewMainQueueChecking>. Break on -[UIView methodCalledNotFromMainQueue:] to catch it in debugger.
 */
- (void)methodCalledNotFromMainQueue:(NSString *)methodName;

@end
