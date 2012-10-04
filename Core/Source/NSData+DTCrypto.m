//
//  NSData+DTCrypto.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 10/3/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSData+DTCrypto.h"
#include <CommonCrypto/CommonHMAC.h>

/**
 Common cryptography methods
 */
@implementation NSData (DTCrypto)


/**
 Encrypts the receiver's data with the given key using the SHA1 algorithm.
 */
- (NSData *)encryptedDataUsingSHA1WithKey:(NSData *)key
{
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, [key bytes], [key length], [self bytes], [self length], cHMAC);
    
    return [NSData dataWithBytes:&cHMAC length:CC_SHA1_DIGEST_LENGTH];
}

@end
