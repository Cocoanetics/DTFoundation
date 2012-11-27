//
//  DTPDFFunctions.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

// functions to convert PDF objects into ObjC

// converts a CGPDFArray into an NSArray
NSArray *_arrayFromPDFArray(CGPDFArrayRef pdfArray);

// converts a CGPDFObject into an NSObject
id _objectForPDFObject(CGPDFObjectRef value);

// function used for scanning PDF dictionaries. The decoded value is added under its key to the passed mutable dictionary
void _setDecodedPDFValueForKey(const char *key, CGPDFObjectRef value, void *mutableDictionary);

#pragma mark - Scanner Callbacks

void _callback_BDC(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_BMC(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_BT(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_DP(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_EMC(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_ET(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_MP(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_Td(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_TD(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_Tf(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_Tj(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_TJ(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_Tm(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_TStar(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_SingleQuote(CGPDFScannerRef inScanner, void *mutableArray);
void _callback_DoubleQuote(CGPDFScannerRef inScanner, void *mutableArray);
