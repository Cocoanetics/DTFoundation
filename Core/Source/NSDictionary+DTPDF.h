//
//  NSDictionary+DTPDF.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Category for `NSDictionary` to work with PDF dictionaries
 */

@interface NSDictionary (DTPDF)

/**
 Create a new dictionary with a PDF dictionary
 @param dictionary The PDF dictionary to decode
 */
+ (NSDictionary *)dictionaryWithCGPDFDictionary:(CGPDFDictionaryRef)dictionary;

@end
