//
//  NSDictionaryDTErrorTest.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSDictionaryDTErrorTest.h"

#if !TARGET_OS_WATCH

@import DTFoundation;

/**
 Tests for NSDictionary+DTError Category
 */
@implementation NSDictionaryDTErrorTest

/**
 Tests to get an NSDictionary out of invalid Plist data
 Has to return an NSError object
 */
- (void)testDictionaryWithContentsOfInvalidPlistData
{
    // get invalid Plist data
    NSString *invalidPlistDataString = @"/usdifusadfuiosdufisudfousdfmsa,s.,-,./&(/&(/=)(=)(=()";
    NSData *plistData = [invalidPlistDataString dataUsingEncoding:NSUTF8StringEncoding];
    
    // do conversion to NSDictionary
    NSError *error = nil;
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfData:plistData error:&error];
    
    // do checks
    XCTAssertNil(dictionary, @"Dictionary has content but should be nil");
    XCTAssertNotNil(error, @"No error occured with invalid Plist data");
}

/**
 Test to get an NSDictionary out of a valid Plist data
 No NSerror has to be returned
 */
- (void)testArrayWithValidPlist
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];

    // get Plist data from file
#if SWIFT_PACKAGE
	NSURL *url = [[[testBundle bundleURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"DTFoundation_DTFoundationTests.bundle"];
	NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
	NSString *finalPath = [resourceBundle pathForResource:@"DictionarySample" ofType:@"plist"];
#else
	NSString *finalPath = [testBundle pathForResource:@"DictionarySample" ofType:@"plist"];
#endif
	
    NSData *plistData = [NSData dataWithContentsOfFile:finalPath];
    
    // do conversion to NSDictionary
    NSError *error = nil;
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfData:plistData error:&error];
    
    // do checks
    XCTAssertNil(error, @"Error occured during parsing of valid Plist data");
    XCTAssertTrue(4 == [[dictionary allValues] count], @"Wrong count of objects in dictionary");
}

@end

#endif
