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

@end
