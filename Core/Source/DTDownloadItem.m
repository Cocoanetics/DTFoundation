//
//  DTDownloadItem.m
//  DTFoundation
//
//  Created by René Pirringer on 1/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTDownloadItem.h"


@implementation DTDownloadItem
{

}

- (id)initWithURL:(NSURL *)URL destinationFile:(NSString *)destinationFile {
	self = [super init];
	if (self) {
		self.URL = URL;
		self.destinationFile = destinationFile;
	}
	return self;
}


- (BOOL)isEqual:(id)object
{
	if ([object isKindOfClass:[DTDownloadItem class]]) {
		DTDownloadItem *other = object;
		return [self.destinationFile isEqualToString:other.destinationFile];
	}
	return NO;
}


@end