//
//  NSStringDTURLEncodingTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.04.16.
//  Copyright © 2016 Cocoanetics. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+DTURLEncoding.h"

@interface NSStringDTURLEncodingTest : XCTestCase

@end

@implementation NSStringDTURLEncodingTest

// issue 101: Plus sign should be encoded (becomes a space otherwise)
- (void)testEmailPlus
{
	NSString *email = @"oliver+test@cocoanetics.com";
	NSString *output = [email stringByURLEncoding];
	NSString *result = @"oliver%2Btest@cocoanetics.com";
	
	XCTAssertEqual(output, result);
}

@end
