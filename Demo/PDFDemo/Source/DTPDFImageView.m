//
//  DTPDFImageView.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/25/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFImageView.h"
#import "DTPDFPage.h"

#import <QuartzCore/QuartzCore.h>

@implementation DTPDFImageView
{
    UIImageView *_imageView;
    
    DTPDFPage *_PDFPage;
}


- (id)initWithPDFPage:(DTPDFPage *)PDFPage
{
    self = [super init];
    
    if (self)
    {
        _PDFPage = PDFPage;
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_imageView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _imageView.frame = self.bounds;
    
    if (!_imageView.image)
    {
        // need to generate image
        _imageView.image = [self _imageforPDFPage];
    }
}

- (UIImage *)_imageforPDFPage
{
    CGSize pageSize = [_PDFPage cropRect].size;
    
    // Drawing code
    UIGraphicsBeginImageContextWithOptions(pageSize, NO, 1);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    [_PDFPage renderInContext:contextRef];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(contextRef);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    UIGraphicsEndImageContext();

    return image;
}


@end
