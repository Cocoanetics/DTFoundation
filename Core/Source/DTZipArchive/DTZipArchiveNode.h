//
//  DTZipArchiveNode.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Holds important values for files or directories to uncompress
 */
@interface DTZipArchiveNode : NSObject

/**
 File or directory name
 */
@property (nonatomic, strong) NSString *name;

/**
 Size of file
 Directories will have size 0
 */
@property (nonatomic, assign) NSUInteger fileSize;

/**
 Specifies if we have a directory or folder
 */
@property (nonatomic, assign, getter=isDirectory) BOOL directory;

@end