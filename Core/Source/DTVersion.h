//
//  DTVersion.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/25/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Class that represents a version number comprised of major, minor and maintenance number separarated by dots. For example "1.2.2".
 
 This encapsulation simplifies comparing versions against each other. Sub-numbers that are omitted on creating a `DTVersion` are assumed to be 0.
 */
@interface DTVersion : NSObject
{
	NSUInteger _majorVersion;
	NSUInteger _minorVersion;
	NSUInteger _maintenanceVersion;
}

/**
 The receiver's major version number.
 */
@property (nonatomic, readonly) NSUInteger majorVersion;

/**
 The receiver's minor version number.
 */
@property (nonatomic, readonly) NSUInteger minorVersion;

/**
 The receiver's maintenance version number.
 */
@property (nonatomic, readonly) NSUInteger maintenanceVersion;

/**-------------------------------------------------------------------------------------
 @name Creating Versions
 ---------------------------------------------------------------------------------------
 */

/**
 creates and returns a `DTVersion` object initialized using the provided string
 
 @param versionString A string with a version number.
 @returns A `DTVersion` object or `nil` if the string is not a valid version number 
 @see initWithMajor:minor:maintenance:
 */
+ (DTVersion *)versionWithString:(NSString *)versionString;

/**
 creates and retuns a `DTVersion` object initialized with the version information of the current application
 
 @returns A `DTVersion` object or `nil` if the string of the current application is not a valid version number 
 */
+ (DTVersion *)appBundleVersion;

/**
 creates and retuns a `DTVersion` object initialized with the version information of the operating system
 
 @returns A `DTVersion` object or `nil` if the string of the current application is not a valid version number 
 */
+ (DTVersion *)osVersion;

/**
 creates and returns a `DTVersion` object initialized using the provided string
 
 @param major The major version number of the version.
 @param minor The minor version number of the version.
 @param maintenance The maintenance version number of the version.
 @returns A `DTVersion` object or `nil` if the string is not a valid version number 
 */
- (DTVersion *)initWithMajor:(NSUInteger)major minor:(NSUInteger)minor maintenance:(NSUInteger)maintenance;

/**-------------------------------------------------------------------------------------
 @name Comparing Versions 
 ---------------------------------------------------------------------------------------
 */

/**
 Returns a Boolean value that indicates whether a given `DTVersion` is equal to the receiver.
 
 @param version The `DTVersion` instance to compare against.
 @returns `YES` if the other object is equal to the receiver 
 */
- (BOOL) isEqualToVersion:(DTVersion *)version;

/**
 Returns a Boolean value that indicates whether a given string is equal to the receiver.
 
 @param versionString The string to compare the receiver against.
 @returns `YES` if the other object is equal to the receiver 
 */
- (BOOL) isEqualToString:(NSString *)versionString;

/**
 Returns a Boolean value that indicates whether a given object is equal to the receiver.
 
 If the other object is an `NSString` then isEqualToString: is called. If it is a `DTVersion` instance isEqualToVersion: is called. 
 @param object An NSString or `DTVersion` to compare against.
 @returns `YES` if the other object is equal to the receiver 
 */
- (BOOL) isEqual:(id)object;

/**
Compares the receiver to object.

 @param version The `DTVersion` instance to compare the receiver with.
 @returns `NSOrderedAscending` if the receiver precedes object in version ordering, `NSOrderedSame` if they are equal, and `NSOrderedDescending` if the receiver is higher than object.
 */
- (NSComparisonResult)compare:(DTVersion *)version;

@end
