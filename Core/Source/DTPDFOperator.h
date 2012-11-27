//
//  DTPDFOperator.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTPDFOperator : NSObject

- (id)initWithName:(NSString *)name value:(id)value;

/**
 @returns The text in a Tj or TJ operator
 */
- (NSString *)text;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) id value;

@property (nonatomic, copy) NSString *tagName;



@end
