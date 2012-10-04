//
//  NSData+DTCrypto.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 10/3/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@interface NSData (DTCrypto)

- (NSData *)encryptedDataUsingSHA1WithKey:(NSData *)key;

@end
