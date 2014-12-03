//
//  DTKeychainGenericAccount.m
//  PL
//
//  Created by Oliver Drobnik on 03/12/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTKeychainGenericPassword.h"

@implementation DTKeychainGenericPassword

- (void)setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqualToString:(__bridge __strong id)(kSecAttrService)])
	{
		[self setValue:value forKey:@"service"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrAccount)])
	{
		[self setValue:value forKey:@"account"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecValueData)])
	{
		_password = [[NSString alloc] initWithData:(NSData *)value encoding:NSUTF8StringEncoding];
	}
	else
	{
		[super setValue:value forKey:key];
	}
}

+ (NSString *)itemClass
{
	return (__bridge NSString *)(kSecClassGenericPassword);
}

- (NSDictionary *)attributesToUpdate
{
	// get basic attributes from super
	NSMutableDictionary *tmpDict = [[super attributesToUpdate] mutableCopy];

	// always write the account name
	if (_account)
	{
		tmpDict[(__bridge __strong id)(kSecAttrAccount)] = _account;
	}

	// include the service name as it is part of the primary key
	if (_service)
	{
		tmpDict[(__bridge __strong id)(kSecAttrService)] = _service;
	}

	// write the password if one is set
	if (_password)
	{
		NSData *data = [_password dataUsingEncoding:NSUTF8StringEncoding];
		tmpDict[(__bridge __strong id)(kSecValueData)] = data;
	}
	
	return [tmpDict copy];
}

- (NSString *)debugDescription
{
	NSMutableString *tmpString = [NSMutableString string];
	
	[tmpString appendFormat:@"<%@", NSStringFromClass([self class])];
	
	if (_service)
	{
		[tmpString appendFormat:@" service='%@'", _service];
	}
	
	if (_account)
	{
		[tmpString appendFormat:@" account='%@'", _account];
	}
	
	[tmpString appendString:@">"];
	
	return [tmpString copy];
}

#pragma mark - Querying

+ (NSDictionary *)keychainItemQueryForService:(NSString *)service account:(NSString *)account
{
	// basic implementation contains item class
	NSMutableDictionary *tmpDict = [[super keychainItemQuery] mutableCopy];
	
	// add service if set
	if (service)
	{
		tmpDict[(__bridge __strong id)kSecAttrService] = service;
	}

	// add acount if set
	if (account)
	{
		tmpDict[(__bridge __strong id)kSecAttrAccount] = account;
	}
	
	return [tmpDict copy];
}

@end
