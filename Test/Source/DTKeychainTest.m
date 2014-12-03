//
//  DTKeychainTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 03/12/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DTKeychain.h"
#import "DTKeychainGenericPassword.h"

@interface DTKeychainTest : XCTestCase

@end

@implementation DTKeychainTest
{
	DTKeychain *_keychain;
}

- (void)setUp
{
    [super setUp];
	
	_keychain = [DTKeychain sharedInstance];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
	
	// clean out all generic items
	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:NULL];
	
	if ([items count])
	{
		[_keychain removeKeychainItems:items error:NULL];
	}
}

- (void)testCreateEmptyGenericPassword
{
	DTKeychainGenericPassword *item = [DTKeychainGenericPassword new];
	
	NSError *error;
	BOOL result = [_keychain writeKeychainItem:item error:&error];
	
	
	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:&error];
	XCTAssertTrue(result, @"%@", [error localizedDescription]);
	XCTAssertEqual([items count], 1, @"There should be one item");
}

- (DTKeychainGenericPassword *)_addFooBarItem
{
	DTKeychainGenericPassword *item = [DTKeychainGenericPassword new];
	item.account = @"foo";
	item.service = @"bar";
	item.password = @"pw";
	
	NSError *error;
	BOOL result = [_keychain writeKeychainItem:item error:&error];
	XCTAssertTrue(result, @"%@", [error localizedDescription]);
	
	return item;
}

- (void)testCreateNormalGenericPassword
{
	[self _addFooBarItem];
	
	NSError *error;
	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:&error];
	XCTAssertTrue(items, @"%@", [error localizedDescription]);
	XCTAssertEqual([items count], 1, @"There should be one item");
	
	
	DTKeychainGenericPassword *item = [items lastObject];
	XCTAssertTrue([item isKindOfClass:[DTKeychainGenericPassword class]], @"class should be DTKeychainGenericPassword");
	
	XCTAssertEqualObjects(item.account, @"foo", @"Account should match");
	XCTAssertEqualObjects(item.service, @"bar", @"Service should match");
	XCTAssertEqualObjects(item.password, @"pw", @"Password should match");
}

- (void)testCreateAndDeleteSingle
{
	DTKeychainGenericPassword *item = [self _addFooBarItem];
	
	NSError *error;
	BOOL result = [_keychain removeKeychainItem:item error:&error];
	XCTAssertTrue(result, @"%@", [error localizedDescription]);

	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:&error];
	XCTAssertTrue(items, @"%@", [error localizedDescription]);
	XCTAssertEqual([items count], 0, @"There should be no item");
}

- (void)testCreateDuplicate
{
	[self _addFooBarItem];
	
	DTKeychainGenericPassword *item2 = [DTKeychainGenericPassword new];
	item2.account = @"foo";
	item2.service = @"bar";
	item2.password = @"pw";
	
	NSError *error;
	BOOL result = [_keychain writeKeychainItem:item2 error:&error];
	XCTAssertFalse(result, @"%@", [error localizedDescription]);
}

- (void)testCreateAndChangePassword
{
	DTKeychainGenericPassword *item = [self _addFooBarItem];
	item.password = @"newpw";
	
	NSError *error;
	BOOL result = [_keychain writeKeychainItem:item error:&error];
	XCTAssertTrue(result, @"%@", [error localizedDescription]);
	
	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:&error];
	XCTAssertTrue(items, @"%@", [error localizedDescription]);
	XCTAssertEqual([items count], 1, @"There should be one item");
	
	item = [items lastObject];
	
	XCTAssertEqualObjects(item.password, @"newpw", @"Password should have been updated");
}

- (void)testCreateAndChangeAccount
{
	DTKeychainGenericPassword *item = [self _addFooBarItem];
	item.account = @"newfoo";
	
	NSError *error;
	BOOL result = [_keychain writeKeychainItem:item error:&error];
	XCTAssertTrue(result, @"%@", [error localizedDescription]);
	
	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:&error];
	XCTAssertTrue(items, @"%@", [error localizedDescription]);
	XCTAssertEqual([items count], 1, @"There should be one item");
	
	item = [items lastObject];
	
	XCTAssertEqualObjects(item.account, @"newfoo", @"Account name should have been updated");
}

- (void)testCreateAndChangeService
{
	DTKeychainGenericPassword *item = [self _addFooBarItem];
	item.service = @"newbar";
	
	NSError *error;
	BOOL result = [_keychain writeKeychainItem:item error:&error];
	XCTAssertTrue(result, @"%@", [error localizedDescription]);
	
	NSArray *items = [_keychain keychainItemsMatchingQuery:[DTKeychainGenericPassword keychainItemQuery] error:&error];
	XCTAssertTrue(items, @"%@", [error localizedDescription]);
	XCTAssertEqual([items count], 1, @"There should be one item");
	
	item = [items lastObject];
	
	XCTAssertEqualObjects(item.service, @"newbar", @"Service name should have been updated");
}

@end
