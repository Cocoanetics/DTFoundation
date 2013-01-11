//
// Created by rene on 08.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
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