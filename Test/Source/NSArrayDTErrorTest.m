//
//  NSArray+DTErrorTest.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSArrayDTErrorTest.h"

#if !TARGET_OS_WATCH

@import DTFoundation;

/**
 Tests for NSArray+DTError Category
 */
@implementation NSArrayDTErrorTest

/**
 Tests to get an NSArray out of invalid Plist data
 Has to return an NSError object
 */
- (void)testArrayWithContentsOfInvalidPlistData
{
    // get invalid Plist data
    NSString *invalidPlistDataString = @"/usdifusadfuiosdufisudfousdfmsa,s.,-,./&(/&(/=)(=)(=()";
    NSData *plistData = [invalidPlistDataString dataUsingEncoding:NSUTF8StringEncoding];
    
    // do conversion to NSArray
    NSError *error = nil;
    NSArray *array = [NSArray arrayWithContentsOfData:plistData error:&error];
   
    // do checks
    XCTAssertNil(array, @"Array has content but should be nil");
    XCTAssertNotNil(error, @"No error occured with invalid Plist data");
}

/**
 Test to get an NSArray out of a valid Plist data
 No NSerror has to be returned
 */
- (void)testArrayWithValidPlist
{
    // get Plist data from file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	
#if SWIFT_PACKAGE
	NSURL *url = [[[testBundle bundleURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"DTFoundation_DTFoundationTests.bundle"];
	NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
	NSString *finalPath = [resourceBundle pathForResource:@"ArraySample" ofType:@"plist"];
#else
	NSString *finalPath = [testBundle pathForResource:@"ArraySample" ofType:@"plist"];
#endif
	
    NSData *plistData = [NSData dataWithContentsOfFile:finalPath];
    
    // do conversion to NSArray
    NSError *error = nil;
    NSArray *array =[NSArray arrayWithContentsOfData:plistData error:&error];
    
    // do checks
    XCTAssertNil(error, @"Error occured during parsing of valid Plist data");
    XCTAssertTrue(3 == [array count], @"Wrong count of objects in array");
}

@end

#endif
