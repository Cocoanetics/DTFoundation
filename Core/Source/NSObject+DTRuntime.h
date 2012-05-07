//
//  NSObject+DTRuntime.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/25/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@interface NSObject (DTRuntime)

+ (void)swizzleMethod:(SEL)selector withMethod:(SEL)otherSelector;
+ (void)swizzleClassMethod:(SEL)selector withMethod:(SEL)otherSelector;

@end
