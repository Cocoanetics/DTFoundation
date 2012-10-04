//
//  DTPDFDocument.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Class that encapsulates a PDF document. It is a wrapper around CGPDFDocument
 */
@interface DTPDFDocument : NSObject

/**-------------------------------------------------------------------------------------
 @name Creating PDF Documents
 ---------------------------------------------------------------------------------------
 */

/**
 Creates and returns a `DTPDFDocument` object initialized from the PDF file at the given file URL.
 
 @param url A file URL
 @returns An initialized PDF document
 */
- (id)initWithURL:(NSURL *)url;

/**
 The number of pages in the receiver
 */
@property (nonatomic, assign, readonly) NSInteger numberOfPages;

/**
 The array of <DTPDFPage> instances representing the pages in the document
 */
@property (nonatomic, strong, readonly) NSArray *pages;

@end
