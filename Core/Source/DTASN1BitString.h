//
//  DTASN1BitString.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/10/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


/**
 Represents a string of bits.
 */
@interface DTASN1BitString : NSObject

/**
 The designated initializer
 */
- (id)initWithData:(NSData *)data unusedBits:(NSUInteger)unusedBits;

/**
 Returns the bit value of the bit at the given index whereas the index is numbering the individual bits.
 */
- (BOOL)valueOfBitAtIndex:(NSUInteger)index;

/**
 The number of bits at the end of the data chunk that are not used
 */
@property (nonatomic, assign) NSUInteger unusedBits;

@end
