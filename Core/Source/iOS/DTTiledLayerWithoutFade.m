//
//  DTTiledLayerWithoutFade.m
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 8/24/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "DTTiledLayerWithoutFade.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@implementation DTTiledLayerWithoutFade

+ (CFTimeInterval)fadeDuration
{
	return 0;
}

+ (BOOL)shouldDrawOnMainThread
{
    return YES;
}

@end

#endif
