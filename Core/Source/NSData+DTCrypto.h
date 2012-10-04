//
//  NSData+DTCrypto.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 10/3/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Useful cryptography methods
 */

@interface NSData (DTCrypto)

/**-------------------------------------------------------------------------------------
 @name Generating HMAC Hashes
 ---------------------------------------------------------------------------------------
 */

/**
 Generates a HMAC from the receiver using the SHA1 algorithm
 @param key The encryption key
 @returns The encrypted hash
 */
- (NSData *)encryptedDataUsingSHA1WithKey:(NSData *)key;

@end
