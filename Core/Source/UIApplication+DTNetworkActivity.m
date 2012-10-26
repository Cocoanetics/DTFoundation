//
//  UIApplication+DTNetworkActivity.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/21/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "UIApplication+DTNetworkActivity.h"

// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(UIApplication_DTNetworkActivity);

static NSUInteger __internalOperationCount = 0;

@implementation UIApplication (DTNetworkActivity)

- (void)pushActiveNetworkOperation
{
	@synchronized(self)
	{
		__internalOperationCount++;
		
		void (^block)() = ^{
			if (!self.isNetworkActivityIndicatorVisible && __internalOperationCount)
			{
				self.networkActivityIndicatorVisible = YES;
			}
		};
		
		if (dispatch_get_main_queue() == dispatch_get_current_queue())
		{
			// already on main thread
			block();
		}
		else 
		{
			dispatch_async(dispatch_get_main_queue(), block);
		}
	}
}

- (void)popActiveNetworkOperation
{
	@synchronized(self)
	{
		if (__internalOperationCount==0)
		{
			// nothing to do
			return;
		}
		
		__internalOperationCount--;
		
		void (^block)() = ^{
			if (self.isNetworkActivityIndicatorVisible && !__internalOperationCount)
			{
				self.networkActivityIndicatorVisible = NO;
			}
		};
		
		
		if (dispatch_get_main_queue() == dispatch_get_current_queue())
		{
			// already on main thread
			block();
		}
		else 
		{
			dispatch_async(dispatch_get_main_queue(), block);
		}
	}
}

@end
