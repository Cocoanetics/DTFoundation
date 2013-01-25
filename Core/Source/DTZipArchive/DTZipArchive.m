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

@interface DTZipArchive ()

/**
 Private dedicated initializer
 */
- (id)initWithFileAtPath:(NSString *)path;

@end


@implementation DTZipArchive
{
    NSString *_path;

    NSArray *_listOfEntries;
}

+ (DTZipArchive *)archiveAtPath:(NSString *)path;
{
    // detect archive type
    NSData *data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMapped error:NULL];

    if (!data)
    {
        return nil;
    }

    // detect file format
    const char *bytes = [data bytes];

    // Create class cluster for PKZip or GZip depending on first bytes
    if (bytes[0]=='P' && bytes[1]=='K')
    {
        return [[DTZipArchivePKZip alloc] initWithFileAtPath:path];
    }
    else
    {
        return [[DTZipArchiveGZip alloc] initWithFileAtPath:path];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ path='%@'>", NSStringFromClass([self class]), self.path];
}

#pragma mark - Abstract Methods

- (id)initWithFileAtPath:(NSString *)path
{
    [NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];

    return self;
}

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
@synthesize listOfEntries = _listOfEntries;

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
