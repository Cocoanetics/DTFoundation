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
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!self.isNetworkActivityIndicatorVisible && __internalOperationCount)
			{
				self.networkActivityIndicatorVisible = YES;
			}
		});
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
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.isNetworkActivityIndicatorVisible && !__internalOperationCount)
			{
				self.networkActivityIndicatorVisible = NO;
			}
		});
	}
}

@end
