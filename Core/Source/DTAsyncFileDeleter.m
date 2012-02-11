//
//  DTAsyncFileDeleter.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTAsyncFileDeleter.h"


static dispatch_queue_t _delQueue;
static dispatch_group_t _delGroup;
static dispatch_once_t onceToken;

static dispatch_queue_t _renameQueue;
static dispatch_group_t _renameGroup;

static DTAsyncFileDeleter *_sharedInstance;

@implementation DTAsyncFileDeleter

+ (DTAsyncFileDeleter *)sharedInstance
{
	static dispatch_once_t instanceOnceToken;
	dispatch_once(&instanceOnceToken, ^{
		_sharedInstance = [[DTAsyncFileDeleter alloc] init];
	});
	
	return _sharedInstance;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		dispatch_once(&onceToken, ^{
			_delQueue = dispatch_queue_create("DTAsyncFileDeleterRemoveQueue", 0);
			_delGroup = dispatch_group_create();
			_renameQueue = dispatch_queue_create("DTAsyncFileDeleterRenameQueue", 0);
			_renameGroup = dispatch_group_create();
		});
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)waitUntilFinished
{
	dispatch_group_wait(_renameGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(_delGroup, DISPATCH_TIME_FOREVER);
}

- (void)removeItemAtPath:(NSString *)path
{
	// make a unique temporary name in tmp folder
	CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
	NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:(__bridge NSString *)newUniqueIdString];
	CFRelease(newUniqueId);
	CFRelease(newUniqueIdString);
	
	// rename the file, AFTER previous renames
	dispatch_group_async(_renameGroup, _renameQueue, ^{
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		if ([fileManager moveItemAtPath:path toPath:tmpPath error:NULL])
		{
			// schedule the removal and immediately return	
			dispatch_group_async(_delGroup, _delQueue, ^{
				// file manager is not used any more in the rename queue, so we reuse it
				[fileManager removeItemAtPath:tmpPath error:NULL];
			});
		}
	});
	
	// block until all renames are done
	dispatch_group_wait(_renameGroup, DISPATCH_TIME_FOREVER);
}

- (void)removeItemAtURL:(NSURL *)URL
{
	NSAssert([URL isFileURL], @"Parameter URL must be a file URL");
	
	[self removeItemAtPath:[URL path]];
}

#pragma mark Notifications
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
	UIDevice *device = [UIDevice currentDevice];
	
	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
	{
		if (!device.multitaskingSupported)
		{
			return;
		}
	}
	
	UIApplication *app = [UIApplication sharedApplication];
	__block UIBackgroundTaskIdentifier backgroundTaskID;
	
	void (^completionBlock)() = ^{
		[app endBackgroundTask:backgroundTaskID];
		backgroundTaskID = UIBackgroundTaskInvalid;
	};
	
	backgroundTaskID = [app beginBackgroundTaskWithExpirationHandler:completionBlock];
	
	// wait for all deletions to be done
	[self waitUntilFinished];
	
	// ... when the syncing task completes:
	if (backgroundTaskID != UIBackgroundTaskInvalid)
	{
		completionBlock();		
	}
}

@end
