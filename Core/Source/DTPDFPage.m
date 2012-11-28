//
//  DTPDFPage.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFPage.h"
#import "DTPDFScanner.h"
#import "NSDictionary+DTPDF.h"
#import "DTPDFTextBox.h"


@interface DTPDFPage () // private
@end

@implementation DTPDFPage
{
    CGPDFPageRef _page;
    
    NSDictionary *_dictionary;
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
    
    CGRect rect = CGContextGetClipBoundingBox(context);
    
    // PDF might be transparent, assume white paper
    CGContextSetGrayFillColor(context, 1, 1);
    CGContextFillRect(context, rect);
    
    // get size of inner cropping rect
    CGRect mediaRect = [self trimRect];
    
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

- (CGRect)trimRect
{
    if (_page)
    {
        return CGPDFPageGetBoxRect(_page, kCGPDFTrimBox);
    }
    
    return CGRectZero;
}

- (NSDictionary *)dictionary
{
    if (!_dictionary)
    {
        CGPDFDictionaryRef dict = CGPDFPageGetDictionary(_page);
        _dictionary = [NSDictionary dictionaryWithCGPDFDictionary:dict];
    }
    
    return _dictionary;
}

#pragma mark - Working with Textual Content
- (NSString *)string
{
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(_page);
    
    NSMutableString *tmpString = nil;
    
    CGRect trimRect = [self trimRect];
    
    DTPDFScanner *scanner = [DTPDFScanner scannerWithCGPDFContentStream:contentStream];
    if ([scanner scanContentStream])
    {
        NSArray *textBoxes = [scanner textBoxes];
        
        if ([textBoxes count])
        {
            tmpString = [NSMutableString string];
            
            for (DTPDFTextBox *oneBox in textBoxes)
            {
                CGPoint point = CGPointMake(oneBox.transform.tx, oneBox.transform.ty);
                
                // quick and dirty: only add text from text boxes inside trim rect
				if (!CGRectContainsPoint(trimRect, point))
                {
                    continue;
                }
                
//                NSLog(@"%f %f %@", oneBox.transform.tx, oneBox.transform.ty, [oneBox string]);
//                
                NSString *text = [oneBox string];
                
                if ([text length])
                {
                    [tmpString appendString:text];
                }
            }
        }
    }
    
    CGPDFContentStreamRelease(contentStream);
    return tmpString;
}

@end
