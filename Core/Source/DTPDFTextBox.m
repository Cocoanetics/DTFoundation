//
//  DTPDFTextBox.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFTextBox.h"
#import "DTPDFOperator.h"
#import "DTFoundation.h"

@implementation DTPDFTextBox
{
    CGAffineTransform _transform;
    NSMutableString *_string;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _string = [NSMutableString string];
        _transform = CGAffineTransformIdentity;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ pos=%.2f,%02f text='%@'>", NSStringFromClass([self class]), _transform.tx, _transform.ty, _string];
}

- (void)appendOperator:(DTPDFOperator *)operator
{
    if ([operator.name isEqualToString:@"Tj"] || [operator.name isEqualToString:@"TJ"])
    {
        NSString *text = [operator text];
        
        if (text)
        {
            [_string appendString:text];
        }
    }
    else if ([operator.name isEqualToString:@"Td"] || [operator.name isEqualToString:@"TD"])
    {
        CGPoint point = [operator.value CGPointValue];
        
        _transform.tx += point.x;
        _transform.ty += point.y;

        [_string appendString:@"\n"];
    }
    else if ([operator.name isEqualToString:@"T*"])
    {
        [_string appendString:@"\n"];
    }
}

- (NSComparisonResult)compareByTransformToOtherBox:(DTPDFTextBox *)otherBox
{
    if (_transform.ty > otherBox.transform.ty)
    {
        return NSOrderedAscending;
    }
    
    if (_transform.ty < otherBox.transform.ty)
    {
        return NSOrderedDescending;
    }

    if (_transform.tx > otherBox.transform.tx)
    {
        return NSOrderedAscending;
    }

    if (_transform.tx < otherBox.transform.tx)
    {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

#pragma mark - Properties

- (NSString *)string
{
    return _string;
}

@synthesize transform = _transform;


@end
