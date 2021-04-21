//
//  DTHTMLParserTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 8/9/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTHTMLParserTest.h"

#if !TARGET_OS_WATCH

@import DTFoundation;

@interface DTHTMLParserTest ()<DTHTMLParserDelegate>

@end

@implementation DTHTMLParserTest

- (void)testNilData
{
	// try to create a parser with nil data
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:nil encoding:NSUTF8StringEncoding];
	
	// make sure that this is nil
	XCTAssertNil(parser, @"Parser Object should be nil");
}


- (void)testPlainFile
{
	NSString *path = [self pathForTestResource:@"html_doctype" ofType:@"html"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];

    DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:data encoding:NSUTF8StringEncoding];
	parser.delegate = self;
	
    XCTAssertTrue([parser parse], @"Cannnot parse");
	XCTAssertNil(parser.parserError, @"There should be no error");
}

- (void)testProcessingInstruction
{
	NSString *path = [self pathForTestResource:@"processing_instruction" ofType:@"html"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:data encoding:NSUTF8StringEncoding];
	parser.delegate = self;
    [parser parse];
	
    XCTAssertTrue([parser parse], @"Cannnot parse");
	XCTAssertNil(parser.parserError, @"There should be no error");
}

#pragma mark DTHTMLParserDelegate

- (void)parser:(DTHTMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data
{
	DTLogDebug(@"target: %@ data: %@", target, data);
}


#pragma mark - Helper

- (NSString *)pathForTestResource:(nullable NSString *)name ofType:(nullable NSString *)ext
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];

#if SWIFT_PACKAGE
	NSURL *url = [[[testBundle bundleURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"DTFoundation_DTFoundationTests.bundle"];
	NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
	NSString *finalPath = [resourceBundle pathForResource:name ofType:ext];
#else
	NSString *finalPath = [testBundle pathForResource:name ofType:ext];
#endif
	
	return finalPath;
}


@end

#endif
