//
//  DTZipArchivePKZip.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchivePKZip.h"
#import "DTZipArchiveNode.h"

@interface DTZipArchivePKZip()

- (void)_buildIndex;

- (void)_createError:(NSString *)errorText withCode:(NSUInteger)code andFireCompletion:(DTZipArchiveUncompressionCompletionBlock)completion;

/**
 Path of zip file
 */
@property (nonatomic, copy, readwrite) NSString *path;

/**
 All files and directories in zip archive
 */
@property (nonatomic, strong, readwrite) NSArray *listOfEntries;

@end

@implementation DTZipArchivePKZip
{
    /**
     Total size of all files uncompressed
     */
    long long _totalSize;

    /**
     Includes files only
     */
    long long _totalNumberOfFiles;

    /**
     Includes files and folders
     */
    long long _totalNumberOfItems;

    NSString *_path;

    NSArray *_listOfEntries;
}

- (id)initWithFileAtPath:(NSString *)sourcePath
{
    self = [super init];
    
    if (self)
    {
        self.path = sourcePath;
        
        [self _buildIndex];
    }

    return self;
}

#pragma mark - Private methods

/**
 Build the index of files to uncompress that we can calculate a progress later when uncompressing.
 */
- (void)_buildIndex
{
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    // open the file for unzipping
    unzFile _unzFile = unzOpen((const char *)[self.path UTF8String]);

    // return if failed
    if (!_unzFile)
    {
        return;
    }

    // get file info
    unz_global_info  globalInfo = {0};

    if (!unzGetGlobalInfo(_unzFile, &globalInfo )==UNZ_OK )
    {
        // there's a problem
        return;
    }

    if (unzGoToFirstFile(_unzFile)!=UNZ_OK)
    {
        // unable to go to first file
        return;
    }

    // enum block can stop loop
    BOOL shouldStop = NO;

    // iterate through all files
    do
    {
        unz_file_info zipInfo ={0};

        if (unzOpenCurrentFile(_unzFile) != UNZ_OK)
        {
            // error uncompressing this file
            return;
        }

        // first call for file info so that we know length of file name
        if (unzGetCurrentFileInfo(_unzFile, &zipInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK)
        {
            // cannot get file info
            unzCloseCurrentFile(_unzFile);
            return;
        }

        // reserve space for file name
        char *fileNameC = (char *)malloc(zipInfo.size_filename+1);

        // second call to get actual file name
        unzGetCurrentFileInfo(_unzFile, &zipInfo, fileNameC, zipInfo.size_filename + 1, NULL, 0, NULL, 0);
        fileNameC[zipInfo.size_filename] = '\0';
        NSString *fileName = [NSString stringWithUTF8String:fileNameC];
        free(fileNameC);

        /*
         // get the file date
         NSDateComponents *comps = [[NSDateComponents alloc] init];

         // NOTE: zips have no time zone
         if (zipInfo.dosDate)
         {
         // dosdate spec: http://msdn.microsoft.com/en-us/library/windows/desktop/ms724247(v=vs.85).aspx

         comps.year = ((zipInfo.dosDate>>25)&127) + 1980;  // 7 bits
         comps.month = (zipInfo.dosDate>>21)&15;  // 4 bits
         comps.day = (zipInfo.dosDate>>16)&31; // 5 bits
         comps.hour = (zipInfo.dosDate>>11)&31; // 5 bits
         comps.minute = (zipInfo.dosDate>>5)&63;	// 6 bits
         comps.second = (zipInfo.dosDate&31) * 2;  // 5 bits
         }
         else
         {
         comps.day = zipInfo.tmu_date.tm_mday;
         comps.month = zipInfo.tmu_date.tm_mon + 1;
         comps.year = zipInfo.tmu_date.tm_year;
         comps.hour = zipInfo.tmu_date.tm_hour;
         comps.minute = zipInfo.tmu_date.tm_min;
         comps.second = zipInfo.tmu_date.tm_sec;
         }
         NSDate *fileDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
         */

        DTZipArchiveNode *file = [[DTZipArchiveNode alloc] init];

        // change to only use forward slashes
        fileName = [fileName stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        
        if ([fileName hasSuffix:@"/"])
        {
            file.directory = YES;
            fileName = [fileName substringToIndex:[fileName length]-1];
        }
        else
        {
            file.directory = NO;
        }

        // save file name and size
        file.name = fileName;
        file.fileSize = zipInfo.uncompressed_size;
        _totalSize += file.fileSize;
        _totalNumberOfItems++;

        // only files are counted
        if (!file.isDirectory)
        {
            _totalNumberOfFiles++;
        }

        // add to list of nodes
        [tmpArray addObject:file];

        // close the current file
        unzCloseCurrentFile(_unzFile);
    }
    while (!shouldStop && unzGoToNextFile(_unzFile )==UNZ_OK);
    
    if ([tmpArray count])
    {
        self.listOfEntries = tmpArray;
    }
}


/**
 Creates an error and fires completion block
 */
- (void)_createError:(NSString *)errorText withCode:(NSUInteger)code andFireCompletion:(DTZipArchiveUncompressionCompletionBlock)completion
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorText};
    NSError *error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:code userInfo:userInfo];

    completion(error);
}


#pragma mark - Overridden methods from DTZipArchive

/**
 Uncompress a PKZip file to a given path

 @param targetPath path to extract the PKZip
 @param completion block that is executed on success or failure (with a given error + description). On success the error is nil.
 */
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
    
    __block long long numberOfFilesUncompressed = 0;
    __block long long numberOfItemsUncompressed = 0;
    __block long long sizeUncompressed = 0;
    
    // creating queue and group for uncompression
    dispatch_queue_t uncompressingQueue = dispatch_queue_create("DTZipArchiveUncompressionQueue", 0);
    dispatch_group_t uncompressingGroup = dispatch_group_create();
    
    dispatch_group_async(uncompressingGroup, uncompressingQueue, ^{
        
        // open the file for unzipping
        unzFile _unzFile = unzOpen((const char *) [_path UTF8String]);
        
        // return if failed
        if (!_unzFile)
        {
            if (completion)
            {
                [self _createError:@"Unable to open file for unzipping" withCode:4 andFireCompletion:completion];
            }
            
            return;
        }
        
        if (unzGoToFirstFile(_unzFile) != UNZ_OK)
        {
            
            if (completion)
            {
                [self _createError:@"Unable to go to first file in zip archive" withCode:3 andFireCompletion:completion];
            }
            
            return;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        // iterate through all files
        for (DTZipArchiveNode *node in _listOfEntries)
        {
            
            if (unzOpenCurrentFile(_unzFile) != UNZ_OK)
            {
                
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unable to open zip file"};
                error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:5 userInfo:userInfo];
                
                return;
            }
            
            // increase size of all files (uncompressed) -> to calculate progress
            sizeUncompressed += node.fileSize;
            float sizeInPercentUncompressed = (float) sizeUncompressed / _totalSize;
            
            // increase number of files -> to calculate progress
            numberOfItemsUncompressed++;
            float itemsInPercentUncompressed = (float) numberOfItemsUncompressed / _totalNumberOfItems;
            
            // percent are calculated like in finder
            // we always use the highest percent value (from size or items)
            float percent = MAX(sizeInPercentUncompressed, itemsInPercentUncompressed);
            
            // append uncompress blocks to file
            __block NSString *filePath = [targetPath stringByAppendingPathComponent:node.name];
            
            if (node.isDirectory)
            {
                if (![fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error])
                {
                    return;
                }
            }
            else
            {
                // For files
                // increase number of files -> to calculate progress
                numberOfFilesUncompressed++;
                
                // create file handle
                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
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
                
                int readBytes;
                unsigned char buffer[BUFFER_SIZE] = {0};
                while ((readBytes = unzReadCurrentFile(_unzFile, buffer, BUFFER_SIZE)) > 0)
                {
                    NSData *fileData = [[NSData alloc] initWithBytes:buffer length:(uint) readBytes];
                    
                    if ([fileData length])
                    {
                        // append data to the file handle
                        [_destinationFileHandle writeData:fileData];
                    }  
                }
                
                [_destinationFileHandle closeFile];

                dispatch_async(dispatch_get_main_queue(), ^{
                    // create progress notification
                    NSDictionary *userInfo = @{@"ProgressPercent" : [NSNumber numberWithFloat:percent],
                            @"TotalNumberOfItems" : [NSNumber numberWithLongLong:_totalNumberOfItems],
                            @"NumberOfItemsUncompressed" : [NSNumber numberWithLongLong:numberOfItemsUncompressed],
                            @"TotalNumberOfFiles" : [NSNumber numberWithLongLong:_totalNumberOfFiles],
                            @"NumberOfFilesUncompressed" : [NSNumber numberWithLongLong:numberOfFilesUncompressed],
                            @"TotalSize" : [NSNumber numberWithLongLong:_totalSize],
                            @"SizeUncompressed" : [NSNumber numberWithLongLong:sizeUncompressed]};

                    [[NSNotificationCenter defaultCenter] postNotificationName:DTZipArchiveProgressNotification object:self userInfo:userInfo];
                });
            }
            
            unzCloseCurrentFile(_unzFile);
            
            unzGoToNextFile(_unzFile);
        }
    });
    
    // wait for completion of uncompression and writing all files in Zip
    dispatch_group_wait(uncompressingGroup, DISPATCH_TIME_FOREVER);
    
#if !OS_OBJECT_USING_OBJC
    dispatch_release(uncompressingQueue);
    dispatch_release(uncompressingGroup);
#endif
    
    if (completion)
    {
        completion(nil);
    }
}


// adapted from: http://code.google.com/p/ziparchive
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock
{
    unsigned char buffer[BUFFER_SIZE] = {0};

    // open the file for unzipping
    unzFile _unzFile = unzOpen((const char *)[_path UTF8String]);

    // return if failed
    if (!_unzFile)
    {
        return;
    }

    // get file info
    unz_global_info  globalInfo = {0};

    if (!unzGetGlobalInfo(_unzFile, &globalInfo )==UNZ_OK )
    {
        // there's a problem
        return;
    }

    if (unzGoToFirstFile(_unzFile)!=UNZ_OK)
    {
        // unable to go to first file
        return;
    }

    // enum block can stop loop
    BOOL shouldStop = NO;

    // iterate through all files
    for (DTZipArchiveNode *node in _listOfEntries)
    {
		unz_file_info zipInfo ={0};
        
        if (unzOpenCurrentFile(_unzFile) != UNZ_OK)
        {
            // error uncompressing this file
            return;
        }
        
        // first call for file info so that we know length of file name
		if (unzGetCurrentFileInfo(_unzFile, &zipInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK)
		{
			// cannot get file info
			unzCloseCurrentFile(_unzFile);
			return;
		}

        if (node.isDirectory)
        {
            // call the enum block
            enumerationBlock(node.name, nil, &shouldStop);
        }
        else
        {

            NSMutableData *tmpData = [[NSMutableData alloc] init];

            NSInteger readBytes;
            while((readBytes = unzReadCurrentFile(_unzFile, buffer, BUFFER_SIZE)) > 0)
            {
                [tmpData appendBytes:buffer length:readBytes];
            }

            // call the enum block
            enumerationBlock(node.name, tmpData, &shouldStop);
        }

        // close the current file
        unzCloseCurrentFile(_unzFile);
        
        unzGoToNextFile(_unzFile);

        if (shouldStop)
        {
            return;
        }
    }
}

#pragma mark - Properties

@synthesize path = _path;
@synthesize listOfEntries = _listOfEntries;


@end