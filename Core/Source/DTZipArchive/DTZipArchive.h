//
//  DTZipArchive.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 12.02.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//


#include "zip.h"
#include "unzip.h"

/**
 Buffer size when unzipping in blocks
 */
#define BUFFER_SIZE 4096

/** This is how the enumeration block needs to look like. Setting *stop to YES will stop the enumeration.
 */
typedef void (^DTZipArchiveEnumerationResultsBlock)(NSString *fileName, NSData *data, BOOL *stop);


/**
 Completion block for uncompressToPath:withCompletion:
 */
typedef void (^DTZipArchiveUncompressionCompletionBlock)(NSError *error);

/**
 Notification for the progress of the uncompressing process
 */
extern NSString * const DTZipArchiveProgressNotification;

/**
* Error domain for NSErrors
*/
extern NSString * const DTZipArchiveErrorDomain;


/** This class represents a compressed file in GZIP or PKZIP format. The used format is auto-detected. 
 
 Dependencies: minizip (in Core/Source/Externals), libz.dylib
 */

@interface DTZipArchive : NSObject


/**
 Path of zip file
*/
@property (nonatomic, copy, readonly) NSString *path;

/**
 All files and directories in zip archive
 */
@property (nonatomic, strong, readonly) NSArray *listOfEntries;

/**-------------------------------------------------------------------------------------
 @name Creating A Zip Archive
 ---------------------------------------------------------------------------------------
 */

/** Creates an instance of DTZipArchive in preparation for enumerating its contents.
 
 Uses the [minizip](http://www.winimage.com/zLibDll/minizip.html) wrapper for zlib to deal with PKZip-format files.
 
 @param path A Path to a compressed file
 @returns An instance of DTZipArchive or `nil` if an error occured
 */
+ (DTZipArchive *)archiveAtPath:(NSString *)path;

/** Enumerates through the files contained in the archive.
 
 If stop is set to `YES` in the enumeration block then the enumeration stops. Note that this parameter is ignored for GZip files since those only contain a single file.
 
 @param enumerationBlock An enumeration block that gets executed for each found and decompressed file
 */
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock;

@end

/**
 Here uncompressing to a targetPath is done
 */
@interface DTZipArchive(Uncompressing)

/**
 Uncompresses the receiver to a given path overwriting existing files.

 @param targetPath path where the zip archive is being uncompressed
 @param completion block that executes when uncompressing is finished. Error is `nil` if successful.
 */
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion;

@end
