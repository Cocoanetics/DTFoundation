//
//  DTVersion.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/25/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.

#import <Foundation/Foundation.h>

/*
  Class that represents a version number comprised of major, minor and maintenance number separarated by dots. For example "1.2.2".
  This encapsulation simplifies comparing versions against each other. Sub-numbers that are omitted on creating a `DTVersion` are assumed to be 0.
 */
@interface DTVersion : NSObject
{
	NSUInteger _major;
	NSUInteger _minor;
	NSUInteger _maintenance;
	NSUInteger _build;
}


@property (nonatomic, readonly) NSUInteger major;
@property (nonatomic, readonly) NSUInteger minor;
@property (nonatomic, readonly) NSUInteger maintenance;
@property (nonatomic, readonly) NSUInteger build;

/*
 creates and returns a DTVersion object initialized using the provided string
 @returns A DTVersion object or <code>nil</code> if the string is not a valid version number 
 */
+ (DTVersion *)versionWithString:(NSString *)versionString;

/*
 creates and retuns a DTVersion object initialized with the version information of the current application
 @returns A DTVersion object or <code>nil</code> if the string of the current application is not a valid version number 
 */
+ (DTVersion *)appBundleVersion;

/*
 creates and retuns a DTVersion object initialized with the version information of the operating system
 @returns A DTVersion object or <code>nil</code> if the string of the current application is not a valid version number 
 */
+ (DTVersion *)osVersion;

/**
* @returns <code>true</code> if the given version string is valid and less then the osVersion
*/
+ (BOOL)osVersionIsLessThen:(NSString *)versionString;


/**
* @returns <code>true</code> if the given version string is valid and greater then the osVersion
*/
+ (BOOL)osVersionIsGreaterThen:(NSString *)versionString;

/**
* @returns <code>true</code> if the give version is less then this version
*/
- (BOOL)isLessThenVersion:(DTVersion *)version;

/**
* @returns <code>true</code> if the give version is greater then this version
*/
- (BOOL)isGreaterThenVersion:(DTVersion *)version;

/**
* @returns <code>true</code> if the give version is less then this version string
*/
- (BOOL)isLessThenVersionString:(NSString *)versionString;

/**
* @returns <code>true</code> if the give version is greater then version string
*/
- (BOOL)isGreaterThenVersionString:(NSString *)versionString;



- (DTVersion *)initWithMajor:(NSUInteger)major minor:(NSUInteger)minor maintenance:(NSUInteger)maintenance;

- (DTVersion *)initWithMajor:(NSUInteger)major minor:(NSUInteger)minor maintenance:(NSUInteger)maintenance build:(NSUInteger)build;

- (BOOL) isEqualToVersion:(DTVersion *)version;
- (BOOL) isEqualToString:(NSString *)versionString;
- (BOOL) isEqual:(id)object;
- (NSComparisonResult)compare:(DTVersion *)version;

@end
