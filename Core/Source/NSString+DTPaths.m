//
//  NSString+DTPaths.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/15/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSString+DTPaths.h"

// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(NSString_DTPaths);

@implementation NSString (DTPaths)

#pragma mark Standard Paths

+ (NSString *)cachesPath
{
	static dispatch_once_t onceToken;
	static NSString *cachedPath;
	
	dispatch_once(&onceToken, ^{
		cachedPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];	
	});
	
	return cachedPath;
}

+ (NSString *)documentsPath
{
	static dispatch_once_t onceToken;
	static NSString *cachedPath;

	dispatch_once(&onceToken, ^{
		cachedPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];	
	});

	return cachedPath;
}

#pragma mark Temporary Paths

+ (NSString *)temporaryPath
{
	static dispatch_once_t onceToken;
	static NSString *cachedPath;
	
	dispatch_once(&onceToken, ^{
		cachedPath = NSTemporaryDirectory();	
	});
	
	return cachedPath;
}

+ (NSString *)pathForTemporaryFile
{
	CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
	NSString *tmpPath = [[NSString temporaryPath] stringByAppendingPathComponent:(__bridge NSString *)newUniqueIdString];
	CFRelease(newUniqueId);
	CFRelease(newUniqueIdString);
	
	return tmpPath;
}

@end
