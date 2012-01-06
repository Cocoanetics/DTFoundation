//
//  UIView+DTFoundation.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 12/23/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "UIView+DTFoundation.h"
#import <QuartzCore/QuartzCore.h>
#import "LoadableCategory.h"

// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(UIView_DTFoundation);

@implementation UIView (DTFoundation)

- (UIImage *)snapshotImage
{
	UIGraphicsBeginImageContext(self.bounds.size);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (void)setRoundedCornersWithRadius:(CGFloat)radius width:(CGFloat)width color:(UIColor *)color
{
	self.clipsToBounds = YES;
	self.layer.cornerRadius = radius;
	self.layer.borderWidth = width;
	
	if (color)
	{
		self.layer.borderColor = color.CGColor;
	}
}
@end
