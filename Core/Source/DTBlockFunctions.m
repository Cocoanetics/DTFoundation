//
//  DTBlockFunctions.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 02.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTBlockFunctions.h"

void DTBlockPerformSyncIfOnMainThreadElseAsync(void (^block)(void))
{
	if ([NSThread isMainThread])
	{
		// can perform synchronous on main thread
		block();
	}
	else
	{
		// need to perform asynchronous
		dispatch_async(dispatch_get_main_queue(), block);
	}
}