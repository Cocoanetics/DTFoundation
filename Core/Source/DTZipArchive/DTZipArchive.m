//
//  DTZipArchive.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 12.02.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTZipArchive.h"
#import "DTZipArchiveGZip.h"
#import "DTZipArchivePKZip.h"

NSString * const DTZipArchiveProgressNotification = @"DTZipArchiveProgressNotification";
NSString * const DTZipArchiveErrorDomain = @"DTZipArchive";


@implementation DTZipArchive

- (id)initWithFileAtPath:(NSString *)sourcePath
{

    NSData *sourceData = [[NSData alloc] initWithContentsOfFile:sourcePath options:NSDataReadingMapped error:NULL];

    if (!sourceData)
    {
        return nil;
    }

    // detect file format
    const char *bytes = [sourceData bytes];

    // Create class cluster for PKZip or GZip depending on first bytes
    if (bytes[0]=='P' && bytes[1]=='K')
    {
        self = [[DTZipArchivePKZip alloc] initWithFileAtPath:sourcePath];
    }
    else
    {
        self = [[DTZipArchiveGZip alloc] initWithFileAtPath:sourcePath];
    }

	return self;
}


#pragma mark - Abstract Methods

/**
 Abstract method -> should be never called here directly
 But have to be implemented in SubClass
 */
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock
{
    [NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];
}

#pragma mark - Properties

@synthesize path;

@end

@implementation DTZipArchive(Uncompressing)

/**
 Abstract method -> should be never called here directly
 But have to be implemented in SubClass
 */
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion
{
    [NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];
}

@end
