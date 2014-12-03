//
//  DTKeychain.h
//  PL
//
//  Created by Oliver Drobnik on 03/12/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

// domain for returned errors
extern NSString * const DTKeychainErrorDomain;

@class DTKeychainItem, DTKeychainItemQuery;

/**
 Wrapper for the iOS/OSX keychain
 */
@interface DTKeychain : NSObject

/**
 The shared instance of DTKeychain
 */
+ (instancetype)sharedInstance;


/**
 @name Finding Keychain Items
 */

/**
 Query the keychain for items matching the query
 @param query The query to find certain keychain items
 @param error An optional output parameter to take on an error if one occurs
 @param Returns an array of results or `nil` if the query failed
 */
- (NSArray *)keychainItemsMatchingQuery:(NSDictionary *)query error:(NSError *__autoreleasing *)error;

/**
 @name Manipulating Keychain Items
 */

/**
 Writes the keychain item to the keychain. If it has a persistent reference it will be an update, if not it will be newly created.
 @param keychainItem The DTKeychainItem to persist
 @param error An optional output parameter to take on an error if one occurs
 @returns `YES` if the operation was successful
 */
- (BOOL)writeKeychainItem:(DTKeychainItem *)keychainItem error:(NSError *__autoreleasing *)error;

/**
 Removes a keychain item from the keychain
 @param keychainItem The DTKeychainItem to remove from the keychain
 @param error An optional output parameter to take on an error if one occurs
 @returns `YES` if the operation was successful
 */
- (BOOL)removeKeychainItem:(DTKeychainItem *)keychainItem error:(NSError *__autoreleasing *)error;

/**
 Removes multiple keychain items from the keychain
 @param keychainItems The keychain items to remove from the keychain
 @param error An optional output parameter to take on an error if one occurs
 @returns `YES` if the operation was successful
 */
- (BOOL)removeKeychainItems:(NSArray *)keychainItems error:(NSError *__autoreleasing *)error;

@end
