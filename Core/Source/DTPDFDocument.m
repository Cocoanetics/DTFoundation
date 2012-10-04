//
//  DTPDFDocument.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFDocument.h"
#import "DTPDFPage.h"
#import "DTUtils.h"

@interface DTPDFPage (private)

- (id)initWithCGPDFPage:(CGPDFPageRef)page;

@end

@implementation DTPDFDocument
{
    CGPDFDocumentRef _pdfDocument;
    NSArray *_pages;
    NSInteger _numberOfPages;
}

- (id)initWithURL:(NSURL *)URL
{
    self = [super init];
    
    if (self)
    {
        [self _loadPDFFromURL:URL];
    }
    
    return self;
}

- (void)dealloc
{
    if (_pdfDocument)
    {
        CGPDFDocumentRelease(_pdfDocument);
    }
}

- (void)_loadPDFFromURL:(NSURL *)URL
{
    NSError *error = nil;
	NSData *data = [NSData dataWithContentsOfURL:URL options:0 error:&error]; // NSMappedRead
	
	// get page
	CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	_pdfDocument = CGPDFDocumentCreateWithProvider(dataProvider);
	
	_numberOfPages = CGPDFDocumentGetNumberOfPages(_pdfDocument);
	
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	for (NSInteger index = 1; index <= _numberOfPages; index++)
	{
		CGPDFPageRef page = CGPDFDocumentGetPage(_pdfDocument, index);
		
		DTPDFPage *newPage = [[DTPDFPage alloc] initWithCGPDFPage:page];
		[tmpArray addObject:newPage];
	}
	
	CGDataProviderRelease(dataProvider);
	
    _pages = [NSArray arrayWithArray:tmpArray];
}

#pragma mark Properties

@synthesize numberOfPages = _numberOfPages;
@synthesize pages = _pages;

@end
