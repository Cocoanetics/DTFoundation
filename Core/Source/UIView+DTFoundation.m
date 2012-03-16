//
//  UIView+DTFoundation.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 12/23/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "UIView+DTFoundation.h"
#import <QuartzCore/QuartzCore.h>


// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(UIView_DTFoundation);

NSString *shadowContext = @"Shadow";

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

- (void)addShadowWithColor:(UIColor *)color alpha:(CGFloat)alpha radius:(CGFloat)radius offset:(CGSize)offset
{
	self.layer.shadowOpacity = alpha;
	self.layer.shadowRadius = radius;
	self.layer.shadowOffset = offset;
	
	if (color)
	{
		self.layer.shadowColor = [color CGColor];
	}
	
	// cannot have masking	
	self.layer.masksToBounds = NO;
}

- (void)updateShadowPathToBounds
{
	// add shadow path, needs to be updated when frame changes
	CGPathRef path = CGPathCreateWithRect(self.bounds, NULL);
	self.layer.shadowPath = path;
	CGPathRelease(path);
}

@end
