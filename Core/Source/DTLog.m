//
//  DTLog.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.08.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTLog.h"

DTLogBlock DTLogHandler = nil;
NSUInteger DTLogLevel = 6;

void DTLogSetLoggerBlock(DTLogBlock handler)
{
	DTLogHandler = [handler copy];
}

void DTLogSetLogLevel(NSUInteger logLevel)
{
	DTLogLevel = logLevel;
}
