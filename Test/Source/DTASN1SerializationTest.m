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
#import "DTASN1BitString.h"

@implementation DTASN1SerializationTest

- (void)testDeserialization
{
	NSString *string = @"MBaAFDxB4o8ICKlMJYmNbcU40PyFjGIX";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
	
	id object = [DTASN1Serialization objectWithData:data];
	
	XCTAssertNotNil(object, @"Should be able to decode as array");
	XCTAssertTrue([object isKindOfClass:[NSArray class]], @"Decoded object should be an array");
}

- (void)testBitString
{
	NSString *string = @"AwIFoA==";
	NSData *data = [DTBase64Coding dataByDecodingString:string];

	DTASN1BitString *bitString = [DTASN1Serialization objectWithData:data];
	
	NSString *asString = [bitString stringWithBits];
	XCTAssertTrue([@"101" isEqualToString:asString], @"Result should be 101");
}

- (void)testUTF8String
{
	NSString *string = @"DApTb21lLVN0YXRl";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
    
	NSString *decodedString = [DTASN1Serialization objectWithData:data];
	
	XCTAssertTrue([@"Some-State" isEqualToString:decodedString], @"Result is not 'Some-State'");
}

// a sequence with no contents should still be returned as array
- (void)testDecodingEmptySequence
{
	NSString *string = @"MAA=";
	NSData *data = [DTBase64Coding dataByDecodingString:string];
	
	id object = [DTASN1Serialization objectWithData:data];
	
	XCTAssertNotNil(object, @"Should be able to decode as array");
	XCTAssertTrue([object isKindOfClass:[NSArray class]], @"Decoded object should be an array");
}

- (void)testDecodingSimpleInt
{
    NSMutableData *data = [NSMutableData new];
    uint8_t byte = 2;
    [data appendBytes:&byte length:1];
    byte = 1;
    [data appendBytes:&byte length:1];
    byte = 3;
    [data appendBytes:&byte length:1];
    
    NSNumber *object = [DTASN1Serialization objectWithData:data];
    XCTAssertEqualObjects(object, @(3));
}

- (void)testDecodingLongInt
{
    NSString *string = @"AgcDjX6mjTpM";
    NSData *data = [DTBase64Coding dataByDecodingString:string];
    
    NSNumber *object = [DTASN1Serialization objectWithData:data];
    
    XCTAssertNotNil(object, @"Should be able to decode as number");
    XCTAssertTrue([object isKindOfClass:[NSNumber class]], @"Decoded object should be a number");
    XCTAssertEqualObjects(object, @(1000000029801036));
}

- (void)testDecodingEmptyString
{
    NSString *string = @"FgA=";
    NSData *data = [DTBase64Coding dataByDecodingString:string];
    
    NSString *object = [DTASN1Serialization objectWithData:data];
    
    XCTAssertNotNil(object, @"Should be able to decode as number");
    XCTAssertTrue([object isKindOfClass:[NSString class]], @"Decoded object should be a string");
    XCTAssertEqualObjects(object, @"");
}

- (void)testCertificateDecoding
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SelfSigned" ofType:@"der"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    id object = [DTASN1Serialization objectWithData:data];
    
	XCTAssertNotNil(object, @"Should be able to decode certificate");
    
    XCTAssertTrue([object isKindOfClass:[NSArray class]], @"Certficate should be decoded as NSArray");
    XCTAssertEqual([object count], (NSUInteger)3, @"Certificate should have 3 sections");
}

@end
