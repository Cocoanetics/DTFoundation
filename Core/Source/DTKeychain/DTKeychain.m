//
//  DTKeychain.m
//  PL
//
//  Created by Oliver Drobnik on 03/12/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTKeychain.h"
#import "DTKeychainItem.h"

// domain for returned errors
NSString * const DTKeychainErrorDomain = @"DTKeychainErrorDomain";

@implementation DTKeychain

+ (instancetype)sharedInstance
{
	static dispatch_once_t onceToken;
	static DTKeychain *_sharedInstance = nil;
	
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[DTKeychain alloc] init];
	});
	
	return _sharedInstance;
}

#pragma mark - Helpers

- (NSError *)_errorWithCode:(NSInteger)code message:(NSString *)message
{
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
	return [NSError errorWithDomain:DTKeychainErrorDomain code:code userInfo:userInfo];
}

- (NSError *)_errorForOSStatus:(OSStatus)OSStatus
{
	switch (OSStatus)
	{
		default:
		case errSecSuccess:
		{
			return nil;
		}
			
		case errSecUnimplemented:
		{
			return [self _errorWithCode:OSStatus message:@"Function or operation not implemented"];
		}

		case errSecIO:
		{
			return [self _errorWithCode:OSStatus message:@"I/O error (bummers)"];
		}

		case errSecOpWr:
		{
			return [self _errorWithCode:OSStatus message:@"File already open with with write permission"];
		}

		case errSecParam:
		{
			return [self _errorWithCode:OSStatus message:@"One or more parameters passed to a function where not valid"];
		}

		case errSecAllocate:
		{
			return [self _errorWithCode:OSStatus message:@"Failed to allocate memory"];
		}

		case errSecUserCanceled:
		{
			return [self _errorWithCode:OSStatus message:@"User canceled the operation"];
		}

		case errSecBadReq:
		{
			return [self _errorWithCode:OSStatus message:@"Bad parameter or invalid state for operation"];
		}

		case errSecInternalComponent:
		{
			return nil;
		}

		case errSecNotAvailable:
		{
			return [self _errorWithCode:OSStatus message:@"No keychain is available. You may need to restart your computer"];;
		}

		case errSecDuplicateItem:
		{
			return [self _errorWithCode:OSStatus message:@"The specified item already exists in the keychain"];;
		}
			
		case errSecItemNotFound:
		{
			return [self _errorWithCode:OSStatus message:@"The specified item could not be found in the keychain"];;
		}

		case errSecInteractionNotAllowed:
		{
			return [self _errorWithCode:OSStatus message:@"User interaction is not allowed"];;
		}
			
		case errSecDecode:
		{
			return [self _errorWithCode:OSStatus message:@"Unable to decode the provided data"];;
		}
			
		case errSecAuthFailed:
		{
			return [self _errorWithCode:OSStatus message:@"The user name or passphrase you entered is not correct"];;
		}
	}
}


#pragma mark - Querying for Keychain Items

- (NSArray *)keychainItemsMatchingQuery:(NSDictionary *)query error:(NSError *__autoreleasing *)error
{
	NSMutableDictionary *tmpDict = [query mutableCopy];
	
	NSString *itemClass = tmpDict[(__bridge __strong id)(kSecClass)];
	NSParameterAssert(itemClass);

	// this will be the class for result items
	Class class = [DTKeychainItem classForItemClass:itemClass];

	// add desired result fields to query
	
	// return all matching values
	tmpDict[(__bridge NSString *)kSecMatchLimit] = (__bridge NSString *)kSecMatchLimitAll;
	
	// get the attributes
	tmpDict[(__bridge NSString *)kSecReturnAttributes] = @(YES);
	
	// we also want to get a persistent reference
	tmpDict[(__bridge NSString *)kSecReturnPersistentRef] = @(YES);
	
	// return secured data
	tmpDict[(__bridge NSString *)kSecReturnData] = @(YES);
	
	
	CFArrayRef result = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFTypeRef)tmpDict, (CFTypeRef *)&result);
	
	if (status == errSecSuccess)
	{
		NSMutableArray *tmpArray = [NSMutableArray array];
		
		for (NSDictionary *oneDict in (__bridge_transfer NSArray *)result)
		{
			DTKeychainItem *item = [[class alloc] initWithDictionary:oneDict];
			[tmpArray addObject:item];
		}
		
		return [tmpArray copy];
	}
	else
	{
		if (error)
		{
			*error = [self _errorForOSStatus:status];
		}
	}
	
	return nil;
}

#pragma mark - Manipulating Keychain Items

- (BOOL)_updateKeychainItem:(DTKeychainItem *)keychainItem error:(NSError *__autoreleasing *)error
{
	NSDictionary *query = @{(__bridge id)kSecValuePersistentRef: keychainItem.persistentReference};
	NSDictionary *attributesToUpdate = [keychainItem attributesToUpdate];
	
	OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)(query),
											  (__bridge CFDictionaryRef)(attributesToUpdate));
	
	if (status == errSecSuccess)
	{
		return YES;
	}
	
	if (error)
	{
		*error = [self _errorForOSStatus:status];
	}
	
	return NO;
}

- (BOOL)_createKeychainItem:(DTKeychainItem *)keychainItem error:(NSError *__autoreleasing *)error
{
	NSMutableDictionary *attributes = [[keychainItem attributesToUpdate] mutableCopy];
	
	// get the attributes
	[attributes setObject:(__bridge id) kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnAttributes];
	
	// we  want to get a persistent reference
	[attributes setObject:@(YES) forKey:(__bridge id<NSCopying>)(kSecReturnPersistentRef)];
	
	
	CFTypeRef result = NULL;
	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)(attributes), (CFTypeRef *)&result);
	
	if (status == errSecSuccess)
	{
		[keychainItem setValuesForKeysWithDictionary:(__bridge NSDictionary *)(result)];
		return YES;
	}
	
	if (error)
	{
		*error = [self _errorForOSStatus:status];
	}
	
	return NO;
}

- (BOOL)writeKeychainItem:(DTKeychainItem *)keychainItem error:(NSError *__autoreleasing *)error
{
	if (keychainItem.persistentReference)
	{
		return [self _updateKeychainItem:keychainItem error:error];
	}
	else
	{
		return [self _createKeychainItem:keychainItem error:error];
	}
}

- (BOOL)removeKeychainItem:(DTKeychainItem *)keychainItem error:(NSError *__autoreleasing *)error
{
	NSAssert(keychainItem.persistentReference, @"There must be a persistent reference to delete a keychain item!");
	
	NSDictionary *query = @{(__bridge id)kSecValuePersistentRef: keychainItem.persistentReference};
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
	
	if (status == errSecSuccess)
	{
		return YES;
	}
	
	if (error)
	{
		*error = [self _errorForOSStatus:status];
	}
	
	return NO;
}

- (BOOL)removeKeychainItems:(NSArray *)keychainItems error:(NSError *__autoreleasing *)error
{
	for (DTKeychainItem *item in keychainItems)
	{
		if (![self removeKeychainItem:item error:error])
		{
			return NO;
		}
	}
	
	return YES;
}

@end
