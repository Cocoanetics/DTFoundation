//
//  DTZipArchiveGZip.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveGZip.h"

@interface DTZipArchiveGZip()

- (NSString *)_inflatedFileName;

/**
 Path of zip file
 */
@property (nonatomic, copy, readwrite) NSString *path;

/**
 All files and directories in zip archive
 */
@property (nonatomic, strong, readwrite) NSArray *listOfEntries;

@end

@implementation DTZipArchiveGZip
{
    /**
     Data field for the zip archive
    */
    NSData *_data;

    NSString *_path;

    NSArray *_listOfEntries;
}


- (id)initWithFileAtPath:(NSString *)sourcePath
{
    self = [super init];
    
    if (self)
    {
        _path = sourcePath;

        _data = [[NSData alloc] initWithContentsOfFile:sourcePath options:NSDataReadingMapped error:NULL];
    }
    
    return self;
}


#pragma mark - Private methods

- (NSString *)_inflatedFileName
{
    NSString *fileName = [self.path lastPathComponent];
    NSString *extension = [fileName pathExtension];

    // man page mentions suffixes .gz, -gz, .z, -z, _z or .Z
    if ([extension isEqualToString:@"gz"] || [extension isEqualToString:@"z"] || [extension isEqualToString:@"Z"])
    {
        fileName = [fileName stringByDeletingPathExtension];
    }
    else if ([fileName hasSuffix:@"-gz"])
    {
        fileName = [fileName substringToIndex:[fileName length]-3];
    }
    else if ([fileName hasSuffix:@"-z"] || [fileName hasSuffix:@"_z"])
    {
        fileName = [fileName substringToIndex:[fileName length]-2];
    }

    return fileName;
}

#pragma mark - Overridden methods from DTZipArchive

// adapted from http://www.cocoadev.com/index.pl?NSDataCategory
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock
{
    NSUInteger dataLength = [_data length];
    NSUInteger halfLength = dataLength / 2;

    NSMutableData *decompressed = [NSMutableData dataWithLength: dataLength + halfLength];
    BOOL done = NO;
    int status;


    z_stream strm;
    strm.next_in = (Bytef *)[_data bytes];
    strm.avail_in = (uInt)dataLength;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;

    // inflateInit2 knows how to deal with gzip format
    if (inflateInit2(&strm, (15+32)) != Z_OK)
    {
        return;
    }

    while (!done)
    {
        // extend decompressed if too short
        if (strm.total_out >= [decompressed length])
        {
            [decompressed increaseLengthBy: halfLength];
        }

        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)[decompressed length] - (uInt)strm.total_out;

        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);

        if (status == Z_STREAM_END)
        {
            done = YES;
        }
        else if (status != Z_OK)
        {
            break;
        }
    }

    if (inflateEnd (&strm) != Z_OK || !done)
    {
        return;
    }

    // set actual length
    [decompressed setLength:strm.total_out];

    // call back block
    enumerationBlock([self _inflatedFileName], decompressed, NULL);
}


// adapted from http://www.cocoadev.com/index.pl?NSDataCategory
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion
{
    __block NSError *error = nil;

    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:&isDirectory] || !isDirectory)
    {
        if (completion)
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Invalid target path"};
            error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:1 userInfo:userInfo];

            completion(error);
        }

        return;
    }

    // creating queue and group for uncompression
    dispatch_queue_t uncompressingQueue = dispatch_queue_create("DTZipArchiveUncompressionQueue", 0);
    dispatch_group_t uncompressingGroup = dispatch_group_create();

    // creating queue and group for file writing (files and directories)
    dispatch_queue_t fileWriteQueue = dispatch_queue_create("DTZipArchiveFileQueue", 0);
    dispatch_group_t fileWriteGroup = dispatch_group_create();


    dispatch_group_async(uncompressingGroup, uncompressingQueue, ^{

        // the last 4 bytes contain the uncompressed size
        // this only works when the uncompressed size of the file is smaller 4GB
        NSRange last4Bytes = NSMakeRange([_data length] - 4, 4);
        char *buffer = malloc(last4Bytes.length);
        [_data getBytes:buffer range:last4Bytes];

        NSUInteger uncompressedLength = 0;

        // shift our bytes to get an NSUInteger
        for (int i=0; i<last4Bytes.length; i++)
        {
            uncompressedLength += buffer[i] << (8 * i);
        }

        NSMutableData *decompressed = [NSMutableData dataWithLength:BUFFER_SIZE];
        BOOL done = NO;
        int status;


        z_stream strm;
        strm.next_in = (Bytef *)[_data bytes];
        strm.avail_in = (uInt)[decompressed length];
        strm.total_out = 0;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;

        // inflateInit2 knows how to deal with gzip format
        if (inflateInit2(&strm, (15+32)) != Z_OK)
        {
            if (completion)
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unable to go to first file in zip archive"};
                error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:3 userInfo:userInfo];
            }

            return;
        }


        NSString *filePath = [targetPath stringByAppendingPathComponent:[self _inflatedFileName]];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];

        NSFileManager *fileManager = [[NSFileManager alloc] init];

        // create file handle
        NSFileHandle *_destinationFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
        if(!_destinationFileHandle)
        {
            // if we have no file create it first
            if (![fileManager createFileAtPath:filePath contents:nil attributes:nil])
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unzip file cannot be created"};
                error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:2 userInfo:userInfo];

                return;
            }

            _destinationFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
            if (!_destinationFileHandle)
            {
                return;
            }
        }

        while (!done)
        {
            // extend decompressed if too short
            strm.next_out = [decompressed mutableBytes];
            strm.avail_out = BUFFER_SIZE;

            float percent = (float)strm.total_out / uncompressedLength;

            // Inflate another chunk.
            status = inflate (&strm, Z_SYNC_FLUSH);

            NSMutableData *decompressedBlock = [decompressed mutableCopy];

            dispatch_group_async(fileWriteGroup, fileWriteQueue, ^{

                // on last block reduce size of decompressed block
                uInt lengthOfBlock = strm.total_out % BUFFER_SIZE;
                if (lengthOfBlock)
                {
                    [decompressedBlock setLength:(uInt)lengthOfBlock];
                }

                [_destinationFileHandle writeData:decompressedBlock];

                dispatch_async(dispatch_get_main_queue(), ^{

                    // prepare progress notification
                    NSDictionary *userInfo =  @{@"ProgressPercent" : [NSNumber numberWithFloat:percent]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:DTZipArchiveProgressNotification object:self userInfo:userInfo];
                });

            });


            if (status == Z_STREAM_END)
            {
                dispatch_async(dispatch_get_main_queue(), ^{

                    // prepare progress notification -> 100%
                    NSDictionary *userInfo =  @{@"ProgressPercent" : [NSNumber numberWithFloat:100.0f]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:DTZipArchiveProgressNotification object:self userInfo:userInfo];
                });

                done = YES;
            }
            else if (status != Z_OK)
            {
                break;
            }
        }

        if (inflateEnd (&strm) != Z_OK || !done)
        {
            return;
        }

    });

    // wait for completion of uncompression and writing all files in Zip
    dispatch_group_wait(uncompressingGroup, DISPATCH_TIME_FOREVER);
    dispatch_group_wait(fileWriteGroup, DISPATCH_TIME_FOREVER);

#if !OS_OBJECT_USING_OBJC
    dispatch_release(uncompressingQueue);
    dispatch_release(uncompressingGroup);
    dispatch_release(fileWriteQueue);
    dispatch_release(fileWriteGroup);
#endif

    if (completion)
    {
        completion(nil);
    }
}

#pragma mark - Properties

@synthesize path = _path;
@synthesize listOfEntries = _listOfEntries;

@end