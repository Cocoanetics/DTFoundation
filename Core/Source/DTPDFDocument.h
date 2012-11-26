//
//  DTPDFDocument.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@class DTPDFPage;

/**
 Class that encapsulates a PDF document. It is a wrapper around CGPDFDocument and modeled after PDFDocument which exists on Mac.
 */
@interface DTPDFDocument : NSObject

/**-------------------------------------------------------------------------------------
 @name Initializing Documents
 ---------------------------------------------------------------------------------------
 */

/**
 Creates and returns a `DTPDFDocument` object initialized from the PDF file at the given file URL.
 
 @param url A file URL
 @returns An initialized PDF document
 */
- (id)initWithURL:(NSURL *)url;

/**-------------------------------------------------------------------------------------
 @name Working with Pages
 ---------------------------------------------------------------------------------------
 */

/**
 Returns the number of pages in the document.
 */
- (NSUInteger)pageCount;

/**
 Returns the page at the specified index number.
 
 Indexes are zero based.
 @param index The page index
 @returns The page at this index
 */
- (DTPDFPage *)pageAtIndex:(NSUInteger)index;

/**
 Gets the index number for the specified page.
 
 @param page The page
 @returns The page index or NSNotFound if the page is not found.
 */
- (NSUInteger)indexForPage:(DTPDFPage *)page;

/**-------------------------------------------------------------------------------------
 @name Determining the Page Class
 ---------------------------------------------------------------------------------------
 */

/**
 Returns the class that is allocated and initialized when page objects are created for the document.
 
 If you want to supply a custom page class, subclass `DTPDFDocument` and implement this method to return your custom class. Note that your custom class must be a subclass of `DTPDFPage`; otherwise, the behavior is undefined.
 
 The default implementation of pageClass returns `[DTPDFPage class]`.
 */
- (Class)pageClass;

@end
