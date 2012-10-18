//
//  NSArray+DTError.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 6/15/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "NSArray+DTError.h"

// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(NSArray_DTError);

@implementation NSArray (DTError)


+ (NSArray *)arrayWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
	NSData *readData = [NSData dataWithContentsOfURL:url];
	
	return [NSArray arrayWithContentsOfData:readData error:error];
}

+ (NSArray *)arrayWithContentsOfFile:(NSString *)path error:(NSError **)error
{
	NSURL *url = [NSURL fileURLWithPath:path];
	return [NSArray arrayWithContentsOfURL:url error:error];
}

+ (NSArray *)arrayWithContentsOfData:(NSData *)data error:(NSError **)error
{
	CFStringRef errorString = NULL;
	
	CFPropertyListRef plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault,
																				 (__bridge CFDataRef)data,
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


@end
