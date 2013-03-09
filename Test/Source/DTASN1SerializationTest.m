//
//  DTASN1SerializationTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/9/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTASN1SerializationTest.h"

#import "DTASN1Serialization.h"
#import "DTBase64Coding.h"

@implementation DTASN1SerializationTest

- (void)testDeserialization
{
	NSString *string = @"MBaAFDxB4o8ICKlMJYmNbcU40PyFjGIX";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
	
	id object = [DTASN1Serialization objectWithData:data];
	NSLog(@"%@", object);
}

@end
