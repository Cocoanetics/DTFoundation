//
//  DTHTMLParserTest.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 8/9/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#if !TARGET_OS_WATCH

#import <XCTest/XCTest.h>

@interface DTHTMLParserTest : XCTestCase

- (void)testNilData;
- (void)testPlainFile;
- (void)testProcessingInstruction;

@end

#endif
