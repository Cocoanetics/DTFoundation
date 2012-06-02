//
//  CGUtils.m
//  iCatalog
//
//  Created by Oliver Drobnik on 7/18/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTUtils.h"

CGSize sizeThatFitsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit)
{
	CGFloat necessaryZoomWidth = sizeToFit.width / originalSize.width;
	CGFloat necessaryZoomHeight = sizeToFit.height / originalSize.height;
	
	CGFloat smallerZoom = MIN(necessaryZoomWidth, necessaryZoomHeight);
	
	CGSize scaledSize = CGSizeMake(roundf(originalSize.width*smallerZoom), roundf(originalSize.height*smallerZoom));
	return scaledSize;
}
