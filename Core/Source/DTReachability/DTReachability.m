//
//  DTReachability.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTReachability.h"
#import "DTLog.h"

#import <arpa/inet.h>

@implementation DTReachability {
	NSMutableSet *_observers;
	SCNetworkReachabilityRef _reachability;
	SCNetworkConnectionFlags _connectionFlags;
}


static DTReachability *_sharedInstance;

+ (DTReachability *) defaultReachability {
	static dispatch_once_t instanceOnceToken;
	dispatch_once(&instanceOnceToken, ^{
		_sharedInstance = [[DTReachability alloc] init];
	});
	
	return _sharedInstance;
}

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		_observers = [[NSMutableSet alloc] init];
	}
	return self;
}


- (id)addReachabilityObserverWithBlock:(void(^)(SCNetworkConnectionFlags connectionFlags))observer
{
	@synchronized(self)
	{
		// copy the block
		DTReachabilityObserverBlock block = [observer copy];
		
		// add it to the observers
		[_observers addObject:block];
		
		
		// first watcher creates reachability
		if (!_reachability)
		{
			_reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "apple.com");
		}
		
		SCNetworkReachabilityContext context = {0, (__bridge void *)_observers, NULL, NULL, NULL};
		
		if(SCNetworkReachabilitySetCallback(_reachability, ReachabilityCallback, &context))
		{
			if(!SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes))
			{
				DTLogError(@"Error: Could not schedule reachability");
				SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
				return nil;
			}
		}
		
		// get the current flags if possible
		if (SCNetworkReachabilityGetFlags(_reachability, &_connectionFlags))
		{
			block(_connectionFlags);
		}
		
		return block;
	}
}

- (void)removeReachabilityObserver:(id)observer
{
	@synchronized(self)
	{
		[_observers removeObject:observer];
		
		// if this was the last we don't need the reachability no longer
		
		if (![_observers count])
		{
			SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
			
			if (SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes))
			{
				DTLogInfo(@"Unscheduled reachability");
			}
			else
			{
				DTLogError(@"Error: Could not unschedule reachability");
			}
			
			_reachability = nil;
		}
	}
}

+ (id)addReachabilityObserverWithBlock:(void(^)(SCNetworkConnectionFlags connectionFlags))observer
{
	return [[DTReachability defaultReachability] addReachabilityObserverWithBlock:observer];
}

+ (void)removeReachabilityObserver:(id)observer {
	return [[DTReachability defaultReachability] removeReachabilityObserver:observer];
}

#pragma mark - Internals

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void* info)
{
	NSSet* observers = (__bridge NSSet*) info;

	@autoreleasepool
	{
		for (DTReachabilityObserverBlock observer in observers)
		{
			observer(flags);
		}
	}
}

@end
