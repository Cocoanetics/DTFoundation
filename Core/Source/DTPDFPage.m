//
//  DTPDFPage.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFPage.h"

@implementation DTPDFPage
{
    CGPDFPageRef _page;
}


- (id)initWithCGPDFPage:(CGPDFPageRef)page;
{
    
    self = [super init];
    
    if (self)
    {
        _page  = page;
        
        CGPDFPageRetain(_page);
    }
    
    return self;
}

- (void)dealloc
{
    if (_page)
    {
        CGPDFPageRelease(_page);
    }
}

#pragma mark - Drawing PDF Pages

- (void)renderInContext:(CGContextRef)context
{
    if (!_page)
    {
        return;
    }
    
    CGSize renderSize;
    renderSize.width = CGBitmapContextGetWidth(context);
    renderSize.height = CGBitmapContextGetHeight(context);
    
    CGRect rect = CGRectMake(0, 0, renderSize.width, renderSize.height);
    
    // PDF might be transparent, assume white paper
    CGContextSetGrayFillColor(context, 1, 1);
    CGContextFillRect(context, rect);
    
    // get size of inner cropping rect
    CGRect mediaRect = [self cropRect];

    // save the state of the context
    CGContextSaveGState(context);
 
    // flip context
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    
    // adjust transformation matrix so that media Rect fits context
    CGContextScaleCTM(context, rect.size.width / mediaRect.size.width, rect.size.height / mediaRect.size.height);
    CGContextTranslateCTM(context, -mediaRect.origin.x, -mediaRect.origin.y);
    
    // draw it beautifully
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetRenderingIntent(context, kCGRenderingIntentPerceptual);
    
    // draw PDF page
    CGContextDrawPDFPage(context, _page);
    
    // clean up
    CGContextRestoreGState(context);
}

#pragma mark - Accessing Information about PDF Pages
- (CGRect)cropRect
{
    if (_page)
    {
        return CGPDFPageGetBoxRect(_page, kCGPDFCropBox);
    }
    
    return CGRectZero;
}

@end
