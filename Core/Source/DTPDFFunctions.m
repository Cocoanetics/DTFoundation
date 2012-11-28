//
//  DTPDFFunctions.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFFunctions.h"
#import "DTPDFScanner.h"
#import "DTPDFOperator.h"
#import "DTFoundation.h"

#pragma mark - Decoding

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
                // strings are not strings, could also be a mapping table
                size_t length = CGPDFStringGetLength(objectString);
                NSData *data = [NSData dataWithBytes:CGPDFStringGetBytePtr(objectString) length:length];
                
                // first character cannot be \0
                char *bytes = (char *)[data bytes];
                if (!*bytes)
                {
                    return data;
                }

                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                if (!string)
                {
                    // not a valid string
                    return data;
                }
                
                // check if this is indeed a string
                
                NSData *reencodedData = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
                
                // reencoded data must be identical with original data
                if ([data isEqualToData:reencodedData])
                {
                    return string;
                }
                else
                {
                    // even though it looked like a string, it isn't
                    return data;
                }
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
                
                CGPDFDictionaryApplyFunction(objectDictionary, _setDecodedPDFValueForKey, (__bridge void *)tmpDictionary);
                
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
                    CGPDFDictionaryApplyFunction(dict, _setDecodedPDFValueForKey, (__bridge void *)streamDict);
                    
                    tmpDict[@"___STREAMINFO___"] = streamDict;
                }
                
                // stream data is encoded, dictionary gives info how to decode it e.g. "FlateDecode"
                
                
                CGPDFDataFormat format;
                NSData *data = CFBridgingRelease(CGPDFStreamCopyData(objectStream, &format));
                
                if (data)
                {
                    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                    tmpDict[@"___STREAMDATA___"] = dataStr;
                }
                
                
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
void _setDecodedPDFValueForKey(const char *key, CGPDFObjectRef value, void *mutableDictionary)
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

#pragma mark - Scanner Callbacks


// Begin a text object, initializing the text matrix, Tm, and the text line matrix, Tlm , to the identity matrix. Text objects shall not be nested; a second BT shall not appear before an ET.
// table 107
void _callback_BT(CGPDFScannerRef inScanner, void *mutableArray)
{
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"BT" value:nil];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Begin a marked-content sequence terminated by a balancing EMC operator. tag shall be a name object indicating the role or significance of the sequence.
// table 320
void _callback_BDC(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"BDC expects a param dictionary, got nothing");
        return;
    }
    
    id paramObject = _objectForPDFObject(pdfObject);
    
    if (![paramObject isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"BDC expects an NSDictionary as parameter, gotten %@", NSStringFromClass([paramObject class]));
        
        return;
    }
    
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"BDC expects a tag string, got nothing");
        return;
    }
    
    id tagObject = _objectForPDFObject(pdfObject);
    
    if (![tagObject isKindOfClass:[NSString class]])
    {
        NSLog(@"BDC expects an NSString as parameter, gotten %@", NSStringFromClass([tagObject class]));
        
        return;
    }
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"BDC" value:paramObject];
    operator.tagName = tagObject;
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Designate a marked-content point with an associated property list. tag shall be a name object indicating the role or significance of the point. properties shall be either an inline dictionary containing the property list or a name object associated with it in the Properties subdictionary of the current resource dictionary (see 14.6.2, “Property Lists”).
// table 320
void _callback_DP(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"BDC expects a param dictionary, got nothing");
        return;
    }
    
    id paramObject = _objectForPDFObject(pdfObject);
    
    if (![paramObject isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"BDC expects an NSDictionary as parameter, gotten %@", NSStringFromClass([paramObject class]));
        
        return;
    }
    
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"BDC expects a tag string, got nothing");
        return;
    }
    
    id tagObject = _objectForPDFObject(pdfObject);
    
    if (![tagObject isKindOfClass:[NSString class]])
    {
        NSLog(@"BDC expects an NSString as parameter, gotten %@", NSStringFromClass([tagObject class]));
        
        return;
    }
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"BDC" value:paramObject];
    operator.tagName = tagObject;
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Begin a marked-content sequence terminated by a balancing EMC operator. tag shall be a name object indicating the role or significance of the sequence.
// table 320
void _callback_BMC(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"BDC expects a tag NSString, got nothing");
        return;
    }
    
    id object = _objectForPDFObject(pdfObject);
    
    if (![object isKindOfClass:[NSString class]])
    {
        NSLog(@"BMC expects an NSString as parameter, gotten %@", NSStringFromClass([object class]));
        
        return;
    }
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"BMC" value:object];
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// End a marked-content sequence begun by a BMC or BDC operator.
// table 320
void _callback_EMC(CGPDFScannerRef inScanner, void *mutableArray)
{
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"EMC" value:nil];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// End a text object, discarding the text matrix.
// table 107
void _callback_ET(CGPDFScannerRef inScanner, void *mutableArray)
{
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"ET" value:nil];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Designate a marked-content point. tag shall be a name object indicating the role or significance of the point.
// table 320
void _callback_MP(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"BDC expects a tag NSString, got nothing");
        return;
    }
    
    id object = _objectForPDFObject(pdfObject);
    
    if (![object isKindOfClass:[NSString class]])
    {
        NSLog(@"BMC expects an NSString as parameter, gotten %@", NSStringFromClass([object class]));
        
        return;
    }
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"BMC" value:object];
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Move to the start of the next line.
// table 108
void _callback_TStar(CGPDFScannerRef inScanner, void *mutableArray)
{
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"T*" value:nil];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Move to the start of the next line, offset from the start of the current line by (tx, ty). tx and ty shall denote numbers expressed in unscaled text space units.
// table 108
void _callback_Td(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"Td couldn't get number parameter");
        return;
    }
    
    id object1 = _objectForPDFObject(pdfObject);
    
    if (![object1 isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Td expects an NSNumber as parameter, gotten %@", NSStringFromClass([object1 class]));
        
        return;
    }
    
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"Td couldn't get second number parameter");
        return;
    }
    
    id object2 = _objectForPDFObject(pdfObject);
    
    if (![object2 isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Td expects an NSNumber as second parameter, gotten %@", NSStringFromClass([object2 class]));
        
        return;
    }
    
    CGPoint point = CGPointMake([object2 floatValue], [object1 floatValue]);
    
    NSValue *value = [NSValue valueWithCGPoint:point];
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"TD" value:value];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Move to the start of the next line, offset from the start of the current line by (tx, ty). As a side effect, this operator shall set the leading parameter in the text state.
// table 108
void _callback_TD(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"TD couldn't get number parameter");
        return;
    }
    
    id object1 = _objectForPDFObject(pdfObject);

    if (![object1 isKindOfClass:[NSNumber class]])
    {
        NSLog(@"TD expects an NSNumber as parameter, gotten %@", NSStringFromClass([object1 class]));
        
        return;
    }

    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"TD couldn't get second number parameter");
        return;
    }

    id object2 = _objectForPDFObject(pdfObject);
    
    if (![object2 isKindOfClass:[NSNumber class]])
    {
        NSLog(@"TD expects an NSNumber as second parameter, gotten %@", NSStringFromClass([object2 class]));
        
        return;
    }

    CGPoint point = CGPointMake([object2 floatValue], [object1 floatValue]);
    
    NSValue *value = [NSValue valueWithCGPoint:point];
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"TD" value:value];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

void _callback_Tf(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"Tf couldn't get first parameter");
        return;
    }
    
    id objectNumber = _objectForPDFObject(pdfObject);
    
    if (![objectNumber isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Tf expects an NSNumber as first parameter, gotten %@", NSStringFromClass([objectNumber class]));
        
        return;
    }

    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"Tf couldn't get second parameter");
        return;
    }

    
    
    id objectName = _objectForPDFObject(pdfObject);
    
    if (![objectName isKindOfClass:[NSString class]])
    {
        NSLog(@"Tf expects an NSNumber as seconds parameter, gotten %@", NSStringFromClass([objectName class]));
        
        return;
    }
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"Tf" value:@[objectName, objectNumber]];
    
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

void _callback_Tj(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    
    if(!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"Tj cannot get string parameter");
        return;
    }
    
    id objectString = _objectForPDFObject(pdfObject);
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"Tj" value:objectString];
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

void _callback_TJ(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    
    bool success = CGPDFScannerPopObject(inScanner, &pdfObject);
    
    if(success)
    {
        id object = _objectForPDFObject(pdfObject);
        
        if (![object isKindOfClass:[NSArray class]])
        {
            NSLog(@"TJ expects an array as parameter, gotten %@", NSStringFromClass([object class]));
            
            return;
        }
        
        DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"TJ" value:object];
        NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
        [array addObject:operator];
        
        if ([[operator text] rangeOfString:@"In cognac or black"].location!=NSNotFound)
        {
            NSLog(@"hier");
        }
    }
}

void _callback_Tm(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGAffineTransform transform;
    
    if (!CGPDFScannerPopNumber(inScanner, &transform.ty))
    {
        NSLog(@"Tm could not decode number for ty");
        return;
    }
    
    if (!CGPDFScannerPopNumber(inScanner, &transform.tx))
    {
        NSLog(@"Tm could not decode number for tx");
        return;
    }
    
    if (!CGPDFScannerPopNumber(inScanner, &transform.d))
    {
        NSLog(@"Tm could not decode number for d");
        return;
    }
    
    if (!CGPDFScannerPopNumber(inScanner, &transform.c))
    {
        NSLog(@"Tm could not decode number for c");
        return;
    }
    
    if (!CGPDFScannerPopNumber(inScanner, &transform.b))
    {
        NSLog(@"Tm could not decode number for b");
        return;
    }
    
    if (!CGPDFScannerPopNumber(inScanner, &transform.a))
    {
        NSLog(@"Tm could not decode number for a");
        return;
    }
    
    NSValue *value = [NSValue valueWithCGAffineTransform:transform];
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"Tm" value:value];
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}

// Move to next line and show text
// table 109
void _callback_SingleQuote(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    
    bool success = CGPDFScannerPopObject(inScanner, &pdfObject);
    
    if(success)
    {
        id object = _objectForPDFObject(pdfObject);
        
        if (![object isKindOfClass:[NSString class]])
        {
            NSLog(@"\' expects an NSString as parameter, gotten %@", NSStringFromClass([object class]));
            
            return;
        }
        
        DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"\'" value:object];
        NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
        [array addObject:operator];
    }
}

// Set word and character spacing, move to next line, and show text
// table 109
void _callback_DoubleQuote(CGPDFScannerRef inScanner, void *mutableArray)
{
    CGPDFObjectRef pdfObject;
    
    if (!CGPDFScannerPopObject(inScanner, &pdfObject))
    {
        NSLog(@"\' operator couldn't get string for first parameter");
        return;
    }
    
    id objectString = _objectForPDFObject(pdfObject);
    
    if (![objectString isKindOfClass:[NSString class]])
    {
        NSLog(@"\' expects an NSString as parameter, gotten %@", NSStringFromClass([objectString class]));
        
        return;
    }
    
    NSLog(@"Warning: not yet implemented reading ac and aw parameters of double quote operator");
    
    DTPDFOperator *operator = [[DTPDFOperator alloc] initWithName:@"\'" value:objectString];
    NSMutableArray *array = (__bridge NSMutableArray *)mutableArray;
    [array addObject:operator];
}
