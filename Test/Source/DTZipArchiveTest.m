//
//  DTZipArchiveTest.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveTest.h"
#import "DTZipArchivePKZip.h"
#import "DTZipArchiveNode.h"

@implementation DTZipArchiveTest

/**
 Very simple test for DTZipArchive to test if the files that are uncompressed with PKZip have the following order
 */
- (void)testPKZip
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    __block NSUInteger iteration = 0;

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {


        switch (iteration)
        {
            case 0:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles"], @"node uncompressed is not as expected");
                break;
            }
            case 1:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/plist"], @"node uncompressed is not as expected");
                break;
            }
            case 2:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/screenshot.png"], @"node uncompressed is not as expected");
                break;
            }
            case 3:
            case 4:
            case 5:
            {
                // ignore __MACOSX/ stuff
                //STAssertTrue([fileName isEqualToString:@"__MACOSX/"], @"node uncompressed is not as expected");
                break;
            }
            case 6:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text"], @"node uncompressed is not as expected");
                break;
            }
            case 7:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere"], @"node uncompressed is not as expected");
                break;
            }
            case 8:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere/Franz.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Franz.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 9:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Oliver.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Oliver.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 10:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Rene"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Rene"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 11:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Stefan.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Stefan.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 12:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/test"], @"node uncompressed is not as expected");
                break;
            }
            case 13:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Info.plist"], @"node uncompressed is not as expected");
                break;
            }
            case 14:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Prefix.pch"], @"node uncompressed is not as expected");
                break;
            }

            default:
                STFail(@"Something went wrong");
        }

        iteration ++;

    }];
}

/**
 Tests if the stop works to abort PKZip uncompression
 */
- (void)testPKZipStop
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    __block NSUInteger iteration = 0;

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

        switch (iteration)
        {
            case 0:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles"], @"node uncompressed is not as expected");

                // explicit stop -> no other iterations have to follow!
                *stop = YES;

                break;
            }

            default:
                STFail(@"Stopping DTZipArchive failed");
        }

        iteration ++;

    }];
}


- (void)testUnncompressingPKZipArchiveToTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {

        STAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/plist/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/Franz.txt"];
        NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Franz.txt"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Oliver.txt"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Oliver.txt"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Rene"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Rene"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected");
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Stefan.txt"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Stefan.txt"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/test/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Info.plist"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Prefix.pch"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        
        // test a file larger than 4K
        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/screenshot.png"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"screenshot.png"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

    }];
}


/**
 Compares 1 given original file with data of file
 
 @param originalFilePath path of the original file to compare
 @param uncomressedFileData data of uncompressed file
 @param uncompressedFileName filename of uncompressed file
 */
- (void)_compareOriginalFile:(NSString *)originalFilePath withUncompressedFileData:(NSData *)uncompressedFileData uncompressedFileName:(NSString *)uncompressedFileName
{
    NSData *originalFileData = [NSData dataWithContentsOfFile:originalFilePath];
    
    STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file: %@ does not match original file: %@", uncompressedFileName, originalFilePath);
}

/**
 Compares 2 given files
 
 @param originalFilePath path of the original file to compare
 @param uncompressedFilePath uncompressed file path for file to compare
 */
- (void)_compareOriginalFile:(NSString *)originalFilePath withUncompressedFile:(NSString *)uncompressedFilePath
{
    NSData *originalFileData = [NSData dataWithContentsOfFile:originalFilePath];
    NSData *uncompressedFileData = [NSData dataWithContentsOfFile:uncompressedFilePath];

    STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file: %@ does not match original file: %@", uncompressedFilePath, originalFilePath);
}

/**
 Tests uncompressing a PKZip to an invalid target path
 */
- (void)testUncompressingPKZipWithInvalidTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive uncompressToPath:@"ILLEGAL PATH!!!" completion:^(NSError *error) {

        STAssertNotNil(error, @"No error with illegal path");
    }];
}


/**
 Tests uncompressing of one single file from PKZip
 */
- (void)testUncompressingSingleFileFromPKZipWithSuccess
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	// choose file as node
	DTZipArchiveNode *zipFiles = (DTZipArchiveNode *)zipArchive.nodes[0];
	DTZipArchiveNode *text = (DTZipArchiveNode *)zipFiles.children[2];
	DTZipArchiveNode *andere = (DTZipArchiveNode *)text.children[0];
	DTZipArchiveNode *franzTxt = (DTZipArchiveNode *)andere.children[0];
	

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[zipArchive uncompressZipArchiveNode:franzTxt toDataWithCompletion:^(NSData *data, NSError *error) {

		STAssertNil(error, @"Error occured when uncompressing one single file: %@", [error localizedDescription]);

		// TODO compare data
		dispatch_semaphore_signal(semaphore);

	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

/**
 Do uncompressing single file test with directory -> ILLEGAL -> Error should be raised
 */
- (void)testUncompressingDirectoryFromPKZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	// choose directory node
	DTZipArchiveNode *rootDirectoryNode = zipArchive.nodes[0];

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[zipArchive uncompressZipArchiveNode:rootDirectoryNode toDataWithCompletion:^(NSData *data, NSError *error) {

		STAssertNotNil(error, @"No error raised when uncompressing directory", nil);
		STAssertTrueNoThrow(error.code == 6, @"Wrong error raised. Error should be 6: %@", [error localizedDescription]);

		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

/**
 Do uncompressing with illegal manually create node -> Error should be raised
 */
- (void)testUncompressingWrongNodeFromPKZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	// create illegal node manually
	DTZipArchiveNode *wrongNode = [[DTZipArchiveNode alloc] init];
	wrongNode.name = @"FALSCHER NAME!!!";
	wrongNode.directory = NO;


	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[zipArchive uncompressZipArchiveNode:wrongNode toDataWithCompletion:^(NSData *data, NSError *error) {

		STAssertNotNil(error, @"No error raised when uncompressing wrong node", nil);
		STAssertTrueNoThrow(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);

		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

/**
 Tests uncompression for GZip
 */
- (void)testGZip
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

        STAssertTrue([fileName isEqualToString:@"gzip_sample.txt"], @"Wrong file got when uncompressing");

    }];
}


/**
 Tests uncompression to a specified target path
 */
- (void)testUncompressingGZipToTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
    [zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {

        STAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
        NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];

        STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		 
		 dispatch_semaphore_signal(semaphore);
    }];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

/**
 Tests uncompressing a GZip to an invalid target path
 */
- (void)testUncompressingGzipWithInvalidTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive uncompressToPath:@"ILLEGAL PATH!!!" completion:^(NSError *error) {

        STAssertNotNil(error, @"No error with illegal path");
    }];
}

/**
 Tests if calling enumerateUncompressedFilesAsDataUsingBlock
 on object created with [[DTZipArchive alloc] init] has to raise an exception
 */
- (void)testAbstractMethodOfDTZipArchive
{
    DTZipArchive *zipArchive = [[DTZipArchive alloc] init];

    STAssertThrowsSpecificNamed([zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

    }] , NSException, @"DTAbstractClassException", @"Calling this method on [[DTZipArchive alloc] init] object should cause exception");

}

@end