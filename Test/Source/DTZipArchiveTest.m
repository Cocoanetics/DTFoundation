//
//  DTZipArchiveTest.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveTest.h"
#import "DTFoundation.h"

@implementation DTZipArchiveTest

/**
 Very simple test for DTZipArchive to test if the files that are uncompressed with PKZip have the following order
 */
- (void)testPKZip
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];

    __block NSUInteger iteration = 0;

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {


        switch (iteration)
        {
            case 0:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/"], @"node uncompressed is not as expected");
                break;
            }
            case 1:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/plist/"], @"node uncompressed is not as expected");
                break;
            }
            case 2:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/"], @"node uncompressed is not as expected");
                break;
            }
            case 3:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere/"], @"node uncompressed is not as expected");
                break;
            }
            case 4:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere/Franz.txt"], @"node uncompressed is not as expected");
                break;
            }
            case 5:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Oliver.txt"], @"node uncompressed is not as expected");
                break;
            }
            case 6:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Rene"], @"node uncompressed is not as expected");
                break;
            }
            case 7:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Stefan.txt"], @"node uncompressed is not as expected");
                break;
            }
            case 8:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/test/"], @"node uncompressed is not as expected");
                break;
            }
            case 9:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Info.plist"], @"node uncompressed is not as expected");
                break;
            }
            case 10:
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

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];

    __block NSUInteger iteration = 0;

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

        switch (iteration)
        {
            case 0:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/"], @"node uncompressed is not as expected");

                // explicit stop -> no other iterations have to follow!
                NSLog(@"Now stopping uncompressing with DTZipArchive");
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

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];

    [zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {

        STAssertNil(error, @"Error occured when uncompressing");


        NSFileManager *fileManager = [NSFileManager defaultManager];


        NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/plist/"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/Franz.txt"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Oliver.txt"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Rene"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected");

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Stefan.txt"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/test/"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Info.plist"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Prefix.pch"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
    }];
}

/**
 Tests uncompressing a PKZip to an invalid target path
 */
- (void)testUncompressingPKZipWithInvalidTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];



    //BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:@"ILLEGAL PATH!!!"];

    [zipArchive uncompressToPath:@"ILLEGAL PATH!!!" completion:^(NSError *error) {

        STAssertNotNil(error, @"No error with illegal path");
    }];
}

/**
 Tests uncompression for GZip
 */
- (void)testGZip
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];

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

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];

    [zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {

        STAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
        NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];

        STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
    }];
}

/**
 Tests uncompressing a GZip to an invalid target path
 */
- (void)testUncompressingGzipWithInvalidTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [[DTZipArchive alloc] initWithFileAtPath:sampleZipPath];

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