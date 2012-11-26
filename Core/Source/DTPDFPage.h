//
//  DTPDFPage.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Class that encapsulates a single page in a PDF document. It is a wrapper around CGPDFPage.
 */
@interface DTPDFPage : NSObject

/**-------------------------------------------------------------------------------------
 @name Drawing PDF Pages
 ---------------------------------------------------------------------------------------
 */

/**
 Renders the receiver into the given graphics context
 @param context a valid `CGContextRef` to render into
 */
- (void)renderInContext:(CGContextRef)context;

/**-------------------------------------------------------------------------------------
 @name Accessing Information about PDF Pages
 ---------------------------------------------------------------------------------------
 */

/**
 Accessing the cropping rect of the receiver
 @returns The cropping rect
 */
- (CGRect)cropRect;

/**
 Accessing the trim rect of the receiver
 @returns The trimming rect
 */
- (CGRect)trimRect;


/**
 Accessing the page dictionary of the receiver
 
 Note: Stream data blobs are omitted for now.
 @returns the dictionary
 */
- (NSDictionary *)dictionary;

/**-------------------------------------------------------------------------------------
 @name Working with Textual Content
 ---------------------------------------------------------------------------------------
 */

/**
 Note: Just raw text, not spacially corrected like in PDFDocument on Mac.

 @returns an NSString object representing the text on the page.
 */
- (NSString *)string;

@end
