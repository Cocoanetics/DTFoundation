//
//  NSDictionary+DTError.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/16/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSDictionary+DTError.h"

// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(NSDictionary_DTError);

@implementation NSDictionary (DTError)

+ (NSDictionary *)dictionaryWithContentsOfURL:(NSURL *)URL error:(NSError **)error
{
	CFPropertyListRef propertyList;
	CFStringRef       errorString;
	CFDataRef         resourceData;
	SInt32            errorCode;
	
	// Read the XML file.
	CFURLCreateDataAndPropertiesFromResource(
													  kCFAllocatorDefault,
													  (__bridge CFURLRef)URL,
													  &resourceData,            // place to put file data
													  NULL,
													  NULL,
													  &errorCode);
	
	// Reconstitute the dictionary using the XML data.
	propertyList = CFPropertyListCreateFromXMLData( kCFAllocatorDefault,
												   resourceData,
												   kCFPropertyListImmutable,
												   &errorString);
	
	
	NSDictionary *readDictionary = nil;
	
	if (resourceData) 
	{
		readDictionary = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)propertyList];
		CFRelease( resourceData );
	}
	else 
	{
		if (errorString)
		{
			if (error)
			{
				NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
				NSString *domain = [infoDict objectForKey:(id)kCFBundleIdentifierKey];
				
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errorString 
																	 forKey:NSLocalizedDescriptionKey];
				*error = [NSError errorWithDomain:domain code:1 userInfo:userInfo];
			}
			
			CFRelease(errorString);
		}
	}
	
	if (propertyList)
	{
		CFRelease(propertyList);
	}
	
	return readDictionary;
}

+ (NSDictionary *)dictionaryWithContentsOfFile:(NSString *)path error:(NSError **)error
{
	NSURL *url = [NSURL fileURLWithPath:path];
	return [NSDictionary dictionaryWithContentsOfURL:url error:error];
}

+ (NSDictionary *)dictionaryWithContentsOfData:(NSData *)data error:(NSError **)error
{
	CFStringRef errorString;
	
	// uses toll-free bridging for data into CFDataRef and CFPropertyList into NSDictionary
	CFPropertyListRef plist =  CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)data,
															   kCFPropertyListImmutable,
															   &errorString);
	
	if (!plist)
	{
		return nil;
	}
	
	// we check if it is the correct type and only return it if it is
	if ([(__bridge id)plist isKindOfClass:[NSDictionary class]])
	{
		return (__bridge_transfer NSDictionary *)plist;
	}
	else
	{
		if (errorString)
		{
			if (error)
			{
				NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
				NSString *domain = [infoDict objectForKey:(id)kCFBundleIdentifierKey];
				
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(__bridge NSString *)errorString 
																	 forKey:NSLocalizedDescriptionKey];
				*error = [NSError errorWithDomain:domain code:1 userInfo:userInfo];
			}
			
			CFRelease(errorString);
		}
		
		// clean up ref
		CFRelease(plist);
		return nil;
	}
}

@end
