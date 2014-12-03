//
//  DTKeychainGenericAccount.h
//  PL
//
//  Created by Oliver Drobnik on 03/12/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTKeychainItem.h"

@class DTKeychainItemQuery;


/**
 A keychain item representing an account password for a generic service.
 */
@interface DTKeychainGenericPassword : DTKeychainItem

/**
 @name Properties
 */

/**
 The name of the service for which the receiver is a password
 */
@property (nonatomic, copy) NSString *service;

/**
 The account name of the receiver
 */
@property (nonatomic, copy) NSString *account;

/**
 The generic password of the receiver
 */
@property (nonatomic, copy) NSString *password;

/**
 @name Constructing Queries
 */

/**
 Constructs a query for generic passwords for the given service. Passing both `nil` for account and service searches for all generic keychain items that the process has access to.
 @param service The optional name of the service
 @param account The optional account name for the query
 */
+ (NSDictionary *)keychainItemQueryForService:(NSString *)service account:(NSString *)account;

@end
