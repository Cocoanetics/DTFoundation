//
//  DTZipArchiveNode.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveNode.h"

@implementation DTZipArchiveNode
{
    NSString *_name;

    NSUInteger _fileSize;

    BOOL _directory;
}

@synthesize name = _name;
@synthesize fileSize = _fileSize;
@synthesize directory = _directory;

@end