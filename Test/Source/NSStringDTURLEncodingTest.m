//
//  NSStringDTURLEncodingTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.04.16.
//  Copyright © 2016 Cocoanetics. All rights reserved.
//

#import <XCTest/XCTest.h>

@import DTFoundation;

@interface NSStringDTURLEncodingTest : XCTestCase

@end

@implementation NSStringDTURLEncodingTest

// issue 101: Plus sign should be encoded (becomes a space otherwise)
- (void)testEmailPlus
{
	NSString *email = @"oliver+test@cocoanetics.com";
	NSString *output = [email stringByURLEncoding];
	NSString *result = @"oliver%2Btest%40cocoanetics.com";
	XCTAssertTrue([output isEqualToString:result]);
}

- (void)testUrlContainsOnlyEnglish
{
    NSString *url = @"https://www.example.com/justenglish#hello";
	NSString *output = [url stringByURLEncoding];
	NSString *result = @"https%3A%2F%2Fwww.example.com%2Fjustenglish%23hello";
    NSURL *uri = [NSURL URLWithString:output];
	XCTAssertTrue([output isEqualToString:result]);
	XCTAssertFalse([uri isEqual:[NSNull null]]);
}

- (void)testUrlContainsQueryParam
{
    NSString *url = @"https://www.example.com/notice?title=hello&name=world";
	NSString *output = [url stringByURLEncoding];
	NSString *result = @"https%3A%2F%2Fwww.example.com%2Fnotice%3Ftitle%3Dhello%26name%3Dworld";
    NSURL *uri = [NSURL URLWithString:output];
	XCTAssertTrue([output isEqualToString:result]);
	XCTAssertFalse([uri isEqual:[NSNull null]]);
}


- (void)testUrlContainsChinese
{
    NSString *url = @"https://www.example.com/你好";
	NSString *output = [url stringByURLEncoding];
	NSString *result = @"https%3A%2F%2Fwww.example.com%2F%E4%BD%A0%E5%A5%BD";
    NSURL *uri = [NSURL URLWithString:output];
	XCTAssertTrue([output isEqualToString:result]);
	XCTAssertFalse([uri isEqual:[NSNull null]]);
}

- (void)testUrlContainsChineseAndEnglish
{
    NSString *url = @"https://www.example.com/just做it";
	NSString *output = [url stringByURLEncoding];
	NSString *result = @"https%3A%2F%2Fwww.example.com%2Fjust%E5%81%9Ait";
	
	XCTAssertTrue([output isEqualToString:result]);
}

@end
