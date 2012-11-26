//
//  DTPDFPage.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFPage.h"



@interface DTPDFPage () // private
@end

// C-functions for PDF scanning
void _applierFunction(const char *key, CGPDFObjectRef value, void *mutableDictionary);
void _scannerCallback(CGPDFScannerRef inScanner, void *userInfo);
NSArray *_arrayFromPDFArray(CGPDFArrayRef pdfArray);
id _objectForPDFObject(CGPDFObjectRef value);

// convert a PDF array into an objC one
NSArray *_arrayFromPDFArray(CGPDFArrayRef pdfArray)
{
    int i = 0;
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    size_t count = CGPDFArrayGetCount(pdfArray);
    for(i=0; i<count; i++)
    {
        CGPDFObjectRef value;
        if (CGPDFArrayGetObject(pdfArray, i, &value))
        {
            id object = _objectForPDFObject(value);
            
            if (object)
            {
                [tmpArray addObject:object];
            }
        }
    }
    
    return tmpArray;
}

// converts a PDF object into an objc object
id _objectForPDFObject(CGPDFObjectRef value)
{
    CGPDFObjectType type = CGPDFObjectGetType(value);
    
    switch (type)
    {
        case kCGPDFObjectTypeNull:
        {
            return [NSNull null];
            
            break;
        }
            
        case kCGPDFObjectTypeBoolean:
        {
            BOOL objectBool;
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeBoolean, &objectBool))
            {
                return [NSNumber numberWithBool:objectBool];
            }
            
            break;
        }
            
        case kCGPDFObjectTypeInteger:
        {
            CGPDFInteger objectInteger;
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeInteger, &objectInteger))
            {
                return [NSNumber numberWithLong:objectInteger];
            }
            
            break;
        }
            
        case kCGPDFObjectTypeReal:
        {
            CGFloat objectReal;
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeReal, &objectReal))
            {
                return [NSNumber numberWithFloat:objectReal];
            }
            
            break;
        }
            
        case kCGPDFObjectTypeName:
        {
            const char *objectName;
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeName, &objectName))
            {
                return [NSString stringWithCString:objectName encoding:NSUTF8StringEncoding];
            }
            
            break;
        }
            
        case kCGPDFObjectTypeString:
        {
            CGPDFStringRef objectString;
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeString, &objectString))
            {
                return (__bridge_transfer NSString *)CGPDFStringCopyTextString(objectString);
            }
            break;
        }
            
        case kCGPDFObjectTypeArray:
        {
            CGPDFArrayRef objectArray;
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeArray, &objectArray))
            {
                return _arrayFromPDFArray(objectArray);
            }
            
            break;
        }
            
        case kCGPDFObjectTypeDictionary:
        {
            CGPDFDictionaryRef objectDictionary = NULL;
            
            if (CGPDFObjectGetValue(value, kCGPDFObjectTypeDictionary, &objectDictionary))
            {
                NSMutableDictionary *tmpDictionary = [[NSMutableDictionary alloc] init];
                
                CGPDFDictionaryApplyFunction(objectDictionary, _applierFunction, (__bridge void *)tmpDictionary);
                
                return tmpDictionary;
            }
            
            break;
        }
            
        case kCGPDFObjectTypeStream:
        {
            CGPDFStreamRef objectStream;
            if(CGPDFObjectGetValue(value, kCGPDFObjectTypeStream, &objectStream))
            {
                NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
                
                CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(objectStream);
                
                NSMutableDictionary *streamDict = [NSMutableDictionary dictionary];
                if(dict)
                {
                    CGPDFDictionaryApplyFunction(dict, _applierFunction, (__bridge void *)streamDict);
                    
                    tmpDict[@"___STREAMINFO___"] = streamDict;
                }
                
                // stream data is encoded, dictionary gives info how to decode it e.g. "FlateDecode"
                
                /*
                CGPDFDataFormat format;
                NSData *data = CFBridgingRelease(CGPDFStreamCopyData(objectStream, &format));
                
                if (data)
                {
                    tmpDict[@"___STREAMDATA___"] = data;
                }
                 */
                
                return tmpDict;
            }
            
            break;
        }
            
        default:
        {
            NSLog(@"Unknown PDF object with key type %d", type);
            break;
        }
    }
    
    return nil;
}

// function for walking through PDF dictionaries
void _applierFunction(const char *key, CGPDFObjectRef value, void *mutableDictionary)
{
     CGPDFObjectType type = CGPDFObjectGetType(value);
    
    if (type == kCGPDFObjectTypeDictionary && !strcmp("Parent", key))
    {
        // need to skip this, otherwise endless loop
        return;
    }
        
    NSMutableDictionary *dictionary = (__bridge NSMutableDictionary *)mutableDictionary;
    
    NSString *keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    
    id object = _objectForPDFObject(value);
    
    if (object)
    {
        dictionary[keyStr] = object;
    }
}

void _scannerCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    NSMutableString *tmpString = (__bridge NSMutableString *)userInfo;
    
    CGPDFObjectRef pdfObject;
    
    bool success = CGPDFScannerPopObject(inScanner, &pdfObject);
    
    if(success)
    {
        id object = _objectForPDFObject(pdfObject);
        
        if ([object isKindOfClass:[NSString class]])
        {
            [tmpString appendString:object];
        }
        else if ([object isKindOfClass:[NSArray class]])
        {
            NSMutableArray *words = [NSMutableArray array];
            
            for (id component in object)
            {
                // ignore the numbers in the array, those are glyph offsets
                if ([component isKindOfClass:[NSString class]])
                {
                    [words addObject:component];
                }
            }
            
            [tmpString appendString:[words componentsJoinedByString:@""]];
        }
    }
}

/*
void _scannerNLCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    NSMutableString *tmpString = (__bridge NSMutableString *)userInfo;

    [tmpString appendString:@"\n"];
}

void _scannerTDCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    NSMutableString *tmpString = (__bridge NSMutableString *)userInfo;
    
    CGPDFObjectRef pdfObject1;
     bool success = CGPDFScannerPopObject(inScanner, &pdfObject1);

        CGPDFObjectRef pdfObject2;
    bool success2 = CGPDFScannerPopObject(inScanner, &pdfObject2);

    
    
    id object = _objectForPDFObject(pdfObject1);
    id object2 = _objectForPDFObject(pdfObject2);
    
    NSLog(@"TD %.2f %.2f", [object floatValue], [object2 floatValue]);
    
    [tmpString appendString:@"\n"];
}

void _scannerTMCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    NSMutableString *tmpString = (__bridge NSMutableString *)userInfo;
    
    CGPDFObjectRef pdfObject1;
    
    CGAffineTransform transform;
    CGPDFScannerPopNumber(inScanner, &transform.a);
    CGPDFScannerPopNumber(inScanner, &transform.b);
    CGPDFScannerPopNumber(inScanner, &transform.c);
    CGPDFScannerPopNumber(inScanner, &transform.d);
    CGPDFScannerPopNumber(inScanner, &transform.tx);
    CGPDFScannerPopNumber(inScanner, &transform.ty);
}


void _scannerBTCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    NSLog(@"BT");
}

void _scannerETCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    NSLog(@"ET");
}
 */

@implementation DTPDFPage
{
    CGPDFPageRef _page;
    
    NSMutableDictionary *_dictionary;
}


- (id)initWithCGPDFPage:(CGPDFPageRef)page;
{
    
    self = [super init];
    
    if (self)
    {
        _page  = page;
        
        CGPDFPageRetain(_page);
    }
    
    return self;
}

- (void)dealloc
{
    if (_page)
    {
        CGPDFPageRelease(_page);
    }
}

#pragma mark - Drawing PDF Pages

- (void)renderInContext:(CGContextRef)context
{
    if (!_page)
    {
        return;
    }
    
    CGRect rect = CGContextGetClipBoundingBox(context);
    
    // PDF might be transparent, assume white paper
    CGContextSetGrayFillColor(context, 1, 1);
    CGContextFillRect(context, rect);
    
    // get size of inner cropping rect
    CGRect mediaRect = [self trimRect];
    
    // save the state of the context
    CGContextSaveGState(context);
    
    // flip context
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    
    // adjust transformation matrix so that media Rect fits context
    CGContextScaleCTM(context, rect.size.width / mediaRect.size.width, rect.size.height / mediaRect.size.height);
    CGContextTranslateCTM(context, -mediaRect.origin.x, -mediaRect.origin.y);
    
    // draw it beautifully
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetRenderingIntent(context, kCGRenderingIntentPerceptual);
    
    // draw PDF page
    CGContextDrawPDFPage(context, _page);
    
    // clean up
    CGContextRestoreGState(context);
}

#pragma mark - Accessing Information about PDF Pages
- (CGRect)cropRect
{
    if (_page)
    {
        return CGPDFPageGetBoxRect(_page, kCGPDFCropBox);
    }
    
    return CGRectZero;
}

- (CGRect)trimRect
{
    if (_page)
    {
        return CGPDFPageGetBoxRect(_page, kCGPDFTrimBox);
    }
    
    return CGRectZero;
}

- (NSDictionary *)dictionary
{
    if (!_dictionary)
    {
        CGPDFDictionaryRef dict = CGPDFPageGetDictionary(_page);
        
        NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
        CGPDFDictionaryApplyFunction(dict, _applierFunction, (__bridge void *)tmpDict);
        
        _dictionary = [tmpDict copy];
    }
    
    return _dictionary;
}

#pragma mark - Working with Textual Content
- (NSString *)string
{
    CGPDFOperatorTableRef operatorTable = CGPDFOperatorTableCreate();
    CGPDFOperatorTableSetCallback (operatorTable, "TJ", &_scannerCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "Tj", &_scannerCallback);
    
    /*
    CGPDFOperatorTableSetCallback (operatorTable, "\'", &_scannerNLCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "\"", &_scannerNLCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "T*", &_scannerNLCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "Tm", &_scannerTMCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "Td", &_scannerTDCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "TD", &_scannerTDCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "BT", &_scannerBTCallback);
    CGPDFOperatorTableSetCallback (operatorTable, "ET", &_scannerETCallback);
     */
    
    NSMutableString *tmpString = [NSMutableString string];
    
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(_page);
    CGPDFScannerRef scanner = CGPDFScannerCreate (contentStream, operatorTable, (__bridge void *)tmpString);
    
    BOOL success = CGPDFScannerScan (scanner);
    
    CGPDFScannerRelease (scanner);
    
    CGPDFContentStreamRelease (contentStream);
    
    CGPDFOperatorTableRelease(operatorTable);
    
    if (success)
    {
        return tmpString;
    }
    else
    {
        return nil;
    }
}

@end
