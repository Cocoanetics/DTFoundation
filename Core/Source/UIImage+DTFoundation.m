//
//  UIImage+DTFoundation.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/8/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "UIImage+DTFoundation.h"

// force this category to be loaded by linker
MAKE_CATEGORIES_LOADABLE(UIImage_DTFoundation);

@implementation UIImage (DTFoundation)

- (void)drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode
{
	CGRect drawRect;
	CGSize size = self.size;
	
	switch (contentMode) 
	{
		case UIViewContentModeRedraw:
		case UIViewContentModeScaleToFill:
		{
			// nothing to do
			[self drawInRect:rect];
			return;
		}
			
		case UIViewContentModeScaleAspectFit:
		{
			CGFloat factor;
			
			if (size.width<size.height)
			{
				factor = rect.size.height / size.height;
				
			}
			else 
			{
				factor = rect.size.width / size.width;
			}
			
			
			size.width = roundf(size.width * factor);
			size.height = roundf(size.height * factor);
			
			// otherwise same as center
			drawRect = CGRectMake(roundf(CGRectGetMidX(rect)-size.width/2.0f), 
								  roundf(CGRectGetMidY(rect)-size.height/2.0f), 
								  size.width,
								  size.height);
			
			break;
		}	
			
		case UIViewContentModeScaleAspectFill:
		{
			CGFloat factor;
			
			if (size.width<size.height)
			{
				factor = rect.size.width / size.width;
				
			}
			else 
			{
				factor = rect.size.height / size.height;
			}
			
			
			size.width = roundf(size.width * factor);
			size.height = roundf(size.height * factor);
			
			// otherwise same as center
			drawRect = CGRectMake(roundf(CGRectGetMidX(rect)-size.width/2.0f), 
								  roundf(CGRectGetMidY(rect)-size.height/2.0f), 
								  size.width,
								  size.height);
			
			break;
		}
			
		case UIViewContentModeCenter:
		{
			drawRect = CGRectMake(roundf(CGRectGetMidX(rect)-size.width/2.0f), 
								  roundf(CGRectGetMidY(rect)-size.height/2.0f), 
								  size.width,
								  size.height);
			break;
		}	
			
		case UIViewContentModeTop:
		{
			drawRect = CGRectMake(roundf(CGRectGetMidX(rect)-size.width/2.0f), 
								  rect.origin.y-size.height, 
								  size.width,
								  size.height);
			break;
		}	
			
		case UIViewContentModeBottom:
		{
			drawRect = CGRectMake(roundf(CGRectGetMidX(rect)-size.width/2.0f), 
								  rect.origin.y-size.height, 
								  size.width,
								  size.height);
			break;
		}
			
		case UIViewContentModeLeft:
		{
			drawRect = CGRectMake(rect.origin.x, 
								  roundf(CGRectGetMidY(rect)-size.height/2.0f), 
								  size.width,
								  size.height);
			break;
		}	
			
		case UIViewContentModeRight:
		{
			drawRect = CGRectMake(CGRectGetMaxX(rect)-size.width, 
								  roundf(CGRectGetMidY(rect)-size.height/2.0f), 
								  size.width,
								  size.height);
			break;
		}
			
		case UIViewContentModeTopLeft:
		{
			drawRect = CGRectMake(rect.origin.x, 
								  rect.origin.y, 
								  size.width,
								  size.height);
			break;
		}
			
		case UIViewContentModeTopRight:
		{
			drawRect = CGRectMake(CGRectGetMaxX(rect)-size.width, 
								  rect.origin.y, 
								  size.width,
								  size.height);
			break;
		}
			
		case UIViewContentModeBottomLeft:
		{
			drawRect = CGRectMake(rect.origin.x, 
								  CGRectGetMaxY(rect)-size.height, 
								  size.width,
								  size.height);
			break;
		}
			
		case UIViewContentModeBottomRight:
		{
			drawRect = CGRectMake(CGRectGetMaxX(rect)-size.width, 
								  CGRectGetMaxY(rect)-size.height, 
								  size.width,
								  size.height);
			break;
		}
			
	}
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	// clip to rect
	CGContextAddRect(context, rect);
	CGContextClip(context);
	
	// draw
	[self drawInRect:drawRect];
	
	CGContextRestoreGState(context);
}

#pragma mark Tiles
- (UIImage *)tileImageAtColumn:(NSUInteger)column ofColumns:(NSUInteger)columns row:(NSUInteger)row ofRows:(NSUInteger)rows
{
	// calculate resulting size
	CGFloat retWidth = roundf(self.size.width / (CGFloat)columns);
	CGFloat retHeight = roundf(self.size.height / (CGFloat)rows);
	
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(retWidth, retHeight), YES, self.scale);
	
	// move the context such that the left/top of the tile is at the left/top of the context
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, -retWidth*column, -retHeight*row);
	
	// draw the image
	[self drawAtPoint:CGPointZero];

	UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return retImage;
}

- (UIImage *)tileImageInClipRect:(CGRect)clipRect inBounds:(CGRect)bounds scale:(CGFloat)scale
{
	UIGraphicsBeginImageContextWithOptions(clipRect.size, YES, scale);


	CGFloat zoom = self.size.width / bounds.size.width;
	
	// this is the part from the origin image
	CGRect clipInOriginal = clipRect;
	clipInOriginal.origin.x *= zoom;
	clipInOriginal.origin.y *= zoom;
	clipInOriginal.size.width *= zoom;
	clipInOriginal.size.height *= zoom;
	
	// move the context such that the left/top of the tile is at the left/top of the context
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, -clipRect.origin.x, -clipRect.origin.y);
	CGContextScaleCTM(context, 1.0/zoom, 1.0/zoom);
	
	// draw the image
	[self drawAtPoint:CGPointZero];

	UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();
	
	return retImage;
}

@end
