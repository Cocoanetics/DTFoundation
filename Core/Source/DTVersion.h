//
//  DTVersion.h
//  iCatalog
//
//  Created by Rene Pirringer on 20.07.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Class that take a version string with the format major.minor.maintenance (e.g. 1.2.2) that is parsed and
 can be compared with other version numbers
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
