//
//  NSDictionary+DTPDF.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSDictionary+DTPDF.h"
#import "DTPDFFunctions.h"

@implementation NSDictionary (DTPDF)

+ (NSDictionary *)dictionaryWithCGPDFDictionary:(CGPDFDictionaryRef)dictionary
{
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
    
    CGPDFDictionaryApplyFunction(dictionary, _setDecodedPDFValueForKey, (__bridge void *)tmpDict);
    
    return [tmpDict copy];
}

@end
