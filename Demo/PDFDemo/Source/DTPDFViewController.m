//
//  DTPDFViewController.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/25/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFViewController.h"
#import "DTPDFImageView.h"
#import "DTPDFPage.h"

@implementation DTPDFViewController
{
    DTPDFPage *_PDFPage;
    
    DTPDFImageView *_PDFImageView;
}

- (id)initWithPDFPage:(DTPDFPage *)PDFPage
{
    self = [super init];
    
    if (self)
    {
        _PDFPage = PDFPage;
    }
    
    return self;
}

- (void)loadView
{
    _PDFImageView = [[DTPDFImageView alloc] initWithPDFPage:_PDFPage];
    _PDFImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    CGRect rect = [UIScreen mainScreen].applicationFrame;
    _PDFImageView.frame = rect;
    
    self.view = _PDFImageView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.alpha = 1;
}

@end
