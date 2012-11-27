//
//  DTPDFOperator.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPDFOperator.h"

@implementation DTPDFOperator
{
    NSString *_name;
    id _value;
    
    NSString *_tagName;
}

- (id)initWithName:(NSString *)name value:(id)value
{
    self = [super init];
    
    if (self)
    {
        _name = name;
        _value = value;
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *tmpString = [NSMutableString stringWithFormat:@"<%@", NSStringFromClass([self class])];

    if (_name)
    {
        [tmpString appendFormat:@" name='%@'", _name];
        
    }

    if (_tagName)
    {
        [tmpString appendFormat:@" tag='%@'", _tagName];
    }
    
    if (_value)
    {
        NSString *valueString = [self text];
        
        if (!valueString)
        {
            valueString = [_value description];
        }
        
        [tmpString appendFormat:@" value='%@'", valueString];
    }
    
    return tmpString;
}

- (NSString *)text
{
    if ([_value isKindOfClass:[NSString class]])
    {
        return _value;
    }

    if ([_value isKindOfClass:[NSArray class]])
    {
        // aggregate the text
        NSMutableArray *words = [NSMutableArray array];
        
        for (id object in _value)
        {
          if ([object isKindOfClass:[NSString class]])
          {
              [words addObject:object];
          }
        }
        
        return [words componentsJoinedByString:@""];
    }

    return nil;
}


#pragma mark - Properties

@synthesize name = _name;
@synthesize value = _value;
@synthesize tagName = _tagName;

@end
