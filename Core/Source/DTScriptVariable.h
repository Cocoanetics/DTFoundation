//
//  DTScriptValue.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTScriptVariable : NSObject

+ (id)scriptVariableWithName:(NSString *)name value:(id)value;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) id value;


@end
