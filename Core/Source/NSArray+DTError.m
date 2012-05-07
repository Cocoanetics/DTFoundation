//
//  NSArray+DTError.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 6/15/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "NSArray+DTError.h"


@implementation NSArray (DTError)


+ (NSArray *)arrayWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
	NSData *readData = [NSData dataWithContentsOfURL:url];
	
	CFStringRef errorString = NULL;
	
	CFPropertyListRef plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, 
															  (__bridge CFDataRef)readData, 
															  kCFPropertyListImmutable,
															  (CFStringRef *)&errorString);

	if (plist)
	{
		NSArray *readArray = [NSArray arrayWithArray:(__bridge id)plist];
		CFRelease(plist);
		
		return readArray;
	}

	if (errorString&&error)
	{
		NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
		NSString *domain = [infoDict objectForKey:(id)kCFBundleIdentifierKey];
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errorString 
															 forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:domain code:1 userInfo:userInfo];
	}

	return nil;			 
}

+ (NSArray *)arrayWithContentsOfFile:(NSString *)path error:(NSError **)error
{
	NSURL *url = [NSURL fileURLWithPath:path];
	return [NSArray arrayWithContentsOfURL:url error:error];
}


@end
