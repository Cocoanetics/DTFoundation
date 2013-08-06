//
//  DTLog.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.08.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTLog.h"

DTLogBlock DTLogHandler = nil;
DTLogLevel DTCurrentLogLevel = DTLogLevelInfo;

void DTLogSetLoggerBlock(DTLogBlock handler)
{
	DTLogHandler = [handler copy];
}

void DTLogSetLogLevel(DTLogLevel logLevel)
{
	DTCurrentLogLevel = logLevel;
}
