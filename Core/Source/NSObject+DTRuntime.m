//
//  NSObject_DTRuntime.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/25/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <objc/runtime.h>
#import "DTObjectBlockExecutor.h"

@implementation NSObject (DTRuntime)

static char DTRuntimeDeallocBlocks;

#pragma mark - Blocks

- (void)addDeallocBlock:(void(^)())block
{
    // don't accept NULL block
    NSParameterAssert(block);
    
    NSMutableArray *deallocBlocks = objc_getAssociatedObject(self, &DTRuntimeDeallocBlocks);

    // add array of dealloc blocks if not existing yet
    if (!deallocBlocks)
    {
        deallocBlocks = [[NSMutableArray alloc] init];
        
        objc_setAssociatedObject(self, &DTRuntimeDeallocBlocks, deallocBlocks, OBJC_ASSOCIATION_RETAIN);
    }
    
    DTObjectBlockExecutor *executor = [DTObjectBlockExecutor blockExecutorWithDeallocBlock:block];
    
    [deallocBlocks addObject:executor];
}

#pragma mark - Method Swizzling

+ (void)swizzleMethod:(SEL)selector withMethod:(SEL)otherSelector
{
	// my own class is being targetted
	Class c = [self class];
	
	// get the methods from the selectors
	Method originalMethod = class_getInstanceMethod(c, selector);
    Method otherMethod = class_getInstanceMethod(c, otherSelector);
	
    if (class_addMethod(c, selector, method_getImplementation(otherMethod), method_getTypeEncoding(otherMethod)))
	{
		class_replaceMethod(c, otherSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	}
	else
	{
		method_exchangeImplementations(originalMethod, otherMethod);
	}
}

+ (void)swizzleClassMethod:(SEL)selector withMethod:(SEL)otherSelector
{
	// my own class is being targetted
	Class c = [self class];
	
	// get the methods from the selectors
	Method originalMethod = class_getClassMethod(c, selector);
    Method otherMethod = class_getClassMethod(c, otherSelector);
	
//    if (class_addMethod(c, selector, method_getImplementation(otherMethod), method_getTypeEncoding(otherMethod)))
//	{
//		class_replaceMethod(c, otherSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
//	}
//	else
//	{
		method_exchangeImplementations(originalMethod, otherMethod);
//	}

}

@end
