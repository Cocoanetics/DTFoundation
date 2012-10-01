//
// Created by rene on 01.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSString+DTUTI.h"


@implementation NSString (DTUTI)

- (NSString *)MIMETypeForFileExtension:(NSString *)extension
{
	CFStringRef typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL);
	NSString *result = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(typeForExt, kUTTagClassMIMEType);
	if (!result) {
		return @"application/octet-stream";
	}
	return result;
}

@end