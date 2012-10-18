//
//  DTScriptExpression.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/17/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@class DTScriptVariable;

typedef void (^DTScriptExpressionParameterEnumerationBlock) (NSString *, DTScriptVariable *, BOOL *);

/**
 Instances of this class represent a single Objective-C script expression
 */

@interface DTScriptExpression : NSObject


/**
 Creates a script expression from an `NSString`
 @string A string representing an Object-C command including square brackets.
 */
+ (DTScriptExpression *)scriptExpressionWithString:(NSString *)string;

/**
 Creates a script expression from an `NSString`
 @string A string representing an Object-C command including square brackets.
 */
- (id)initWithString:(NSString *)string;

@property (nonatomic, readonly) NSArray *parameters;

- (void)enumerateParametersWithBlock:(DTScriptExpressionParameterEnumerationBlock)block;

@end
