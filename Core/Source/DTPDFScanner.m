//
//  DTPDFScanner.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFScanner.h"
#import "DTPDFFunctions.h"
#import "DTPDFOperator.h"
#import "DTPDFTextBox.h"
#import "DTFoundation.h"

#pragma mark - C Helper Functions

@implementation DTPDFScanner
{
    CGPDFContentStreamRef _contentStream;
    
    NSMutableDictionary *_operatorBlocks;
    CGPDFOperatorTableRef _operatorTable;
    
    NSArray *_textBoxes;
}

+ (id)scannerWithCGPDFContentStream:(CGPDFContentStreamRef)contentStream;
{
    return [[DTPDFScanner alloc] initWithCGPDFContentStream:(CGPDFContentStreamRef)contentStream];
}

- (id)initWithCGPDFContentStream:(CGPDFContentStreamRef)contentStream
{
    self = [super init];
    
    if (self)
    {
        _contentStream = contentStream;
        CGPDFContentStreamRetain(_contentStream);
        
        [self _setupOperatorTable];
    }
    
    return self;
}

- (void)dealloc
{
    if (_contentStream)
    {
        CGPDFContentStreamRelease(_contentStream);
    }
    
    if (_operatorTable)
    {
        CGPDFOperatorTableRelease(_operatorTable);
    }
}

- (void)_setupOperatorTable
{
    _operatorTable = CGPDFOperatorTableCreate();
    
    CGPDFOperatorTableSetCallback (_operatorTable, "BDC", &_callback_BDC);
    CGPDFOperatorTableSetCallback (_operatorTable, "BMC", &_callback_BMC);
    CGPDFOperatorTableSetCallback (_operatorTable, "BT", &_callback_BT);
    CGPDFOperatorTableSetCallback (_operatorTable, "DP", &_callback_DP);
    CGPDFOperatorTableSetCallback (_operatorTable, "EMC", &_callback_EMC);
    CGPDFOperatorTableSetCallback (_operatorTable, "ET", &_callback_ET);
    CGPDFOperatorTableSetCallback (_operatorTable, "MP", &_callback_MP);
    CGPDFOperatorTableSetCallback (_operatorTable, "Td", &_callback_Td);
    CGPDFOperatorTableSetCallback (_operatorTable, "TD", &_callback_TD);
    CGPDFOperatorTableSetCallback (_operatorTable, "Tf", &_callback_Tf);
    CGPDFOperatorTableSetCallback (_operatorTable, "Tj", &_callback_Tj);
    CGPDFOperatorTableSetCallback (_operatorTable, "TJ", &_callback_TJ);
    CGPDFOperatorTableSetCallback (_operatorTable, "Tm", &_callback_Tm);
    CGPDFOperatorTableSetCallback (_operatorTable, "T*", &_callback_TStar);
    CGPDFOperatorTableSetCallback (_operatorTable, "\'", &_callback_SingleQuote);
    CGPDFOperatorTableSetCallback (_operatorTable, "\"", &_callback_DoubleQuote);
}


- (NSArray *)_textBoxesFromOperations:(NSArray *)operations
{
    DTPDFTextBox *currentTextBox = nil;
    CGAffineTransform currentTransform;
    BOOL _firstTransformInBox;
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    for (DTPDFOperator *operator in operations)
    {
        if ([operator.name isEqualToString:@"BT"])
        {
            currentTextBox = [[DTPDFTextBox alloc] init];
            [tmpArray addObject:currentTextBox];
            
            _firstTransformInBox = YES;
        }
        else if ([operator.name isEqualToString:@"Tm"])
        {
            CGAffineTransform newTransform = [operator.value CGAffineTransformValue];
            
            if (newTransform.ty != currentTransform.ty)
            {
                // assume that this is new text box
                currentTextBox = [[DTPDFTextBox alloc] init];
                [tmpArray addObject:currentTextBox];
                
                _firstTransformInBox = YES;
            }

            if (_firstTransformInBox)
            {
                currentTextBox.transform = newTransform;
                _firstTransformInBox = NO;
            }
            
            currentTransform = newTransform;
        }
        else if ([operator.name isEqualToString:@"Tj"])
        {
            [currentTextBox appendOperator:operator];
        }
        else if ([operator.name isEqualToString:@"TJ"])
        {
            [currentTextBox appendOperator:operator];
        }
        else if ([operator.name isEqualToString:@"T*"])
        {
            [currentTextBox appendOperator:operator];
        }
        else if ([operator.name isEqualToString:@"Td"] || [operator.name isEqualToString:@"TD"])
        {
            CGPoint point = [operator.value CGPointValue];
            
            if (point.y>0)
            {
                // move upwards?! must be new box
                // assume that this is new text box
                currentTextBox = [[DTPDFTextBox alloc] init];
                currentTextBox.transform = currentTransform;
                [tmpArray addObject:currentTextBox];
                
                _firstTransformInBox = YES;
            }
            
            [currentTextBox appendOperator:operator];
        }
        else if ([operator.name isEqualToString:@"\'"])
        {
            [currentTextBox appendOperator:operator];
        }
        else if ([operator.name isEqualToString:@"\""])
        {
            [currentTextBox appendOperator:operator];
        }
        else if ([operator.name isEqualToString:@"ET"])
        {
            // ends the box
            currentTextBox = nil;
        }
    }
    
    return tmpArray;
}

- (BOOL)scanContentStream
{
    if (!_contentStream && !_operatorTable)
    {
        return NO;
    }
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    CGPDFScannerRef scanner = CGPDFScannerCreate (_contentStream, _operatorTable, (__bridge void *)tmpArray);
    
    BOOL success = CGPDFScannerScan (scanner);
    
    if (success)
    {
        NSArray *allBoxes = [self _textBoxesFromOperations:tmpArray];
        _textBoxes = [allBoxes sortedArrayUsingSelector:@selector(compareByTransformToOtherBox:)];
    }
    
    CGPDFScannerRelease (scanner);
    
    return success;
}


- (NSArray *)textBoxes
{
    return _textBoxes;
}

@end
