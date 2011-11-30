//
//  DTVersion.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/25/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "DTVersion.h"
#import <UIKit/UIKit.h>

@implementation DTVersion

- (DTVersion *)initWithMajor:(NSUInteger)majorVersion minor:(NSUInteger)minorVersion maintenance:(NSUInteger)maintenanceVersion
{
	self = [super init];
	if (self) 
	{
		_majorVersion = majorVersion;
		_minorVersion = minorVersion;
		_maintenanceVersion = maintenanceVersion;
	}
	return self;
}

+ (DTVersion *)versionWithString:(NSString*)versionString
{
	if (!versionString)
	{
		return nil;
	}
	
	NSInteger major = 0;
	NSInteger minor = 0;
	NSInteger maintenance = 0;
	
	int i=0;
	NSScanner *scanner = [NSScanner scannerWithString:versionString];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"."]];

	while (i<3 && ![scanner isAtEnd]) 
	{
		switch (i) 
		{
			case 0:
			{
				if (![scanner scanInteger:&major]) 
				{
					return nil;
				}
				break;
			}
				
			case 1:
			{
				if (![scanner scanInteger:&minor]) 
				{
					return nil;
				};
				break;
			}
				
			case 2:
			{
				if (![scanner scanInteger:&maintenance]) 
				{
					return nil;
				};
				break;
			}
				
			default:
			{
				// ignore suffix
				break;
			}
		}
		i++;
	}

	if (major >= 0 &&
			minor >= 0 &&
			maintenance >= 0)
	{
		return [[DTVersion alloc] initWithMajor:major minor:minor maintenance:maintenance];
	}
		
	return nil;
}

+ (DTVersion*)appBundleVersion 
{
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	DTVersion* retVersion = [DTVersion versionWithString:version];
	
	return retVersion;
}

+ (DTVersion *)osVersion
{
	NSString *version = [[UIDevice currentDevice] systemVersion];
	return [DTVersion versionWithString:version];
}

- (BOOL) isEqualToVersion:(DTVersion *)version
{
	return (self.majorVersion == version.majorVersion) && (self.minorVersion == version.minorVersion) && (self.maintenanceVersion == version.maintenanceVersion);
}

- (BOOL) isEqualToString:(NSString *)versionString
{
	DTVersion *versionToTest = [DTVersion versionWithString:versionString];
	return [self isEqualToVersion:versionToTest];
}


- (BOOL) isEqual:(id)object
{
	if ([object isKindOfClass:[DTVersion class]]) 
	{
		return [self isEqualToVersion:(DTVersion*)object];
	}
	if ([object isKindOfClass:[NSString class]]) 
	{
		return [self isEqualToString:(NSString*)object];
	}
	return NO;
}

- (NSComparisonResult)compare:(DTVersion *)version
{
	if (version == nil)
	{
		return NSOrderedDescending;
	}
	
	if (self.majorVersion < version.majorVersion)
	{
		return NSOrderedAscending;
	}
	if (self.majorVersion > version.majorVersion)
	{
		return NSOrderedDescending;
	}
	if (self.minorVersion < version.minorVersion)
	{
		return NSOrderedAscending;
	}
	if (self.minorVersion > version.minorVersion)
	{
		return NSOrderedDescending;
	}
	if (self.maintenanceVersion < version.maintenanceVersion)
	{
		return NSOrderedAscending;
	}
	if (self.maintenanceVersion > version.maintenanceVersion)
	{
		return NSOrderedDescending;
	}			
	
	return NSOrderedSame;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"%d.%d.%d", _majorVersion, _minorVersion, _maintenanceVersion];
}



@synthesize majorVersion = _majorVersion;
@synthesize minorVersion = _minorVersion;
@synthesize maintenanceVersion = _maintenanceVersion;
	
@end
