//
//  UIView+DTDebug.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 2/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "UIView+DTDebug.h"
#import "NSObject+DTRuntime.h"

@implementation UIView (DTDebug)


- (void)methodCalledNotFromMainQueue:(NSString *)methodName
{
    NSLog(@"-[%@ %@] being called on background queue. Break on -[UIView methodCalledNotFromMainQueue:] to find out where", NSStringFromClass([self class]), methodName);
}

- (void)_setNeedsLayout_MainQueueCheck
{
    if (dispatch_get_current_queue() != dispatch_get_main_queue())
    {
        [self methodCalledNotFromMainQueue:NSStringFromSelector(_cmd)];
    }
    
    // not really an endless loop, this calls the original
    [self _setNeedsLayout_MainQueueCheck]; 
}

- (void)_setNeedsDisplay_MainQueueCheck
{
    if (dispatch_get_current_queue() != dispatch_get_main_queue())
    {
        [self methodCalledNotFromMainQueue:NSStringFromSelector(_cmd)];
    }
    
    // not really an endless loop, this calls the original
    [self _setNeedsDisplay_MainQueueCheck];
}

- (void)_setNeedsDisplayInRect_MainQueueCheck:(CGRect)rect
{
    if (dispatch_get_current_queue() != dispatch_get_main_queue())
    {
        [self methodCalledNotFromMainQueue:NSStringFromSelector(_cmd)];
    }
    
    // not really an endless loop, this calls the original
    [self _setNeedsDisplayInRect_MainQueueCheck:rect];
}

+ (void)toggleViewMainQueueChecking
{
	[UIView swizzleMethod:@selector(setNeedsLayout) withMethod:@selector(_setNeedsLayout_MainQueueCheck)];
	[UIView swizzleMethod:@selector(setNeedsDisplay) withMethod:@selector(_setNeedsDisplay_MainQueueCheck)];
	[UIView swizzleMethod:@selector(setNeedsDisplayInRect:) withMethod:@selector(_setNeedsDisplayInRect_MainQueueCheck:)];
}


@end
