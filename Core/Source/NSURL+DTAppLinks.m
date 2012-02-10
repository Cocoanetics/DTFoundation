//
//  NSURL+DTAppLinks.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/25/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "NSURL+DTAppLinks.h"


// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(NSURL_DTAppLinks);

@implementation NSURL (DTAppLinks)

+ (NSURL *)appStoreURLforApplicationIdentifier:(NSString *)identifier
{
	NSString *link = [NSString stringWithFormat:@"itms://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@&mt=8", 
					  identifier];
	
	return [NSURL URLWithString:link];
}

+ (NSURL *)appStoreReviewURLForApplicationIdentifier:(NSString *)identifier
{
	NSString *link = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@",
					  identifier];
	return [NSURL URLWithString:link];
}

@end
