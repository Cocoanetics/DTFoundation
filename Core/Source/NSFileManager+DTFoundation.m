//
//  NSFileManager+DTFoundation.m
//  iCatalog
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSFileManager+DTFoundation.h"


// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(NSFoundation_DTFoundation);

@implementation NSFileManager (DTFoundation)

- (void)removeItemAsynchronousAtPath:(NSString *)path
{
	// FIXME: How can this method synchronize itself if it is called twice for the same name versus in short succession for two large files?
	//@synchronized(self)
	{
		// move it to a tmp name to that it appears gone
		CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
		NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:(__bridge NSString *)newUniqueIdString];
		CFRelease(newUniqueId);
		CFRelease(newUniqueIdString);
		
		if (![self moveItemAtPath:path toPath:tmpPath error:NULL])
		{
			// looks like the file is no longer there
			return;
		}
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[self removeItemAtPath:tmpPath error:NULL];
		});
	}
}

- (void)removeItemAsynchronousAtURL:(NSURL *)URL
{
	NSAssert([URL isFileURL], @"Parameter URL has to a file URL");
	
	[self removeItemAsynchronousAtPath:[URL path]];
}


@end
