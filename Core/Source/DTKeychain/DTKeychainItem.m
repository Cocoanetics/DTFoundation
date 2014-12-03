//
//  DTKeychainAccount.m
//  PL
//
//  Created by Oliver Drobnik on 03/12/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTKeychainItem.h"
#import "DTKeychainGenericPassword.h"

@implementation DTKeychainItem
{
	NSData *_genericAttribute;
	BOOL _tombStone;
	NSData *_sha1; // encountered after creating a new item
}

+ (Class)classForItemClass:(NSString *)itemClass
{
	if ([itemClass isEqualToString:[DTKeychainGenericPassword itemClass]])
	{
		return [DTKeychainGenericPassword class];
	}
	
	return nil;
}

+ (NSString *)itemClass
{
	return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	
	if (self)
	{
		[self setValuesForKeysWithDictionary:dictionary];
	}
	
	return self;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqualToString:(__bridge __strong id)(kSecValuePersistentRef)])
	{
		[self setValue:value forKey:@"persistentReference"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrModificationDate)])
	{
		[self setValue:value forKey:@"modificationDate"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrCreationDate)])
	{
		[self setValue:value forKey:@"creationDate"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrAccessGroup)])
	{
		[self setValue:value forKey:@"accessGroup"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrSynchronizable)])
	{
		[self setValue:value forKey:@"synchronizable"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrAccessible)])
	{
		[self setValue:value forKey:@"accessibilityMode"];
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrAccessControl)])
	{
		// ignore
	}
	else if ([key isEqualToString:(__bridge __strong id)(kSecAttrGeneric)])
	{
		_genericAttribute = value;
	}
	else if ([key isEqualToString:@"tomb"])  // kSecAttrTombstone
	{
		_tombStone = [value boolValue];
	}
	else if ([key isEqualToString:@"sha1"])  // encountered after new item create
	{
		_sha1 = value;
	}
	else
	{
		[super setValue:value forKey:key];
	}
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"Undefined key '%@' value %@", key, value);
}

- (NSString *)debugDescription
{
	NSMutableString *tmpString = [NSMutableString string];
	
	[tmpString appendFormat:@"<%@>", NSStringFromClass([self class])];
	
	return [tmpString copy];
}

#pragma mark - Querying

+ (NSDictionary *)keychainItemQuery
{
	// there must be always an item class present
	NSString *itemClass = [[self class] itemClass];
	return @{(__bridge __strong id)(kSecClass): itemClass};
}

- (NSDictionary *)attributesToUpdate
{
	// there must be always an item class present
	NSString *itemClass = [[self class] itemClass];
	return @{(__bridge __strong id)(kSecClass): itemClass};
}


/*
 
 For a keychain item of class kSecClassGenericPassword, the primary key is the combination of kSecAttrAccount and kSecAttrService.
 For a keychain item of class kSecClassInternetPassword, the primary key is the combination of kSecAttrAccount, kSecAttrSecurityDomain, kSecAttrServer, kSecAttrProtocol, kSecAttrAuthenticationType, kSecAttrPort and kSecAttrPath.
 For a keychain item of class kSecClassCertificate, the primary key is the combination of kSecAttrCertificateType, kSecAttrIssuer and kSecAttrSerialNumber.
 For a keychain item of class kSecClassKey, the primary key is the combination of kSecAttrApplicationLabel, kSecAttrApplicationTag, kSecAttrKeyType, kSecAttrKeySizeInBits, kSecAttrEffectiveKeySize, and the creator, start date and end date which are not exposed by SecItem yet.
 For a keychain item of class kSecClassIdentity I haven't found info on the primary key fields in the open source files, but as an identity is the combination of a private key and a certificate, I assume the primary key is the combination of the primary key fields for kSecClassKey and kSecClassCertificate.#
 
 http://www.opensource.apple.com/source/Security/Security-55471/sec/Security/SecItemConstants.c
 */

@end
