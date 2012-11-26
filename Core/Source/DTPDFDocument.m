//
//  DTPDFDocument.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFDocument.h"
#import "DTPDFPage.h"

@interface DTPDFPage (private)

- (id)initWithCGPDFPage:(CGPDFPageRef)page;

@end

@implementation DTPDFDocument
{
    CGPDFDocumentRef _pdfDocument;
    NSArray *_pages;
    NSUInteger _pageCount;
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
	
	_pageCount = CGPDFDocumentGetNumberOfPages(_pdfDocument);
	
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	for (NSInteger index = 1; index <= _pageCount; index++)
	{
		CGPDFPageRef page = CGPDFDocumentGetPage(_pdfDocument, index);
		
		DTPDFPage *newPage = [[DTPDFPage alloc] initWithCGPDFPage:page];
		[tmpArray addObject:newPage];
	}
	
	CGDataProviderRelease(dataProvider);
	
    _pages = [NSArray arrayWithArray:tmpArray];
}

#pragma - mark Working with Pages

- (NSUInteger)pageCount
{
    return _pageCount;
}

- (DTPDFPage *)pageAtIndex:(NSUInteger)index
{
    return _pages[index];
}

- (NSUInteger)indexForPage:(DTPDFPage *)page
{
    return [_pages indexOfObject:page];
}

#pragma mark - Determining the Page Class

- (Class)pageClass
{
    return [DTPDFPage class];
}

@end
