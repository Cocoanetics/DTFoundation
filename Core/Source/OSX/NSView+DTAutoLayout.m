//
//  NSView+DTAutoLayout.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 26.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSView+DTAutoLayout.h"

@implementation NSView (DTAutoLayout)

- (void)addLayoutConstraintWithWidthGreaterOrEqualThan:(CGFloat)width
{
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:width];
    constraint.priority = NSLayoutPriorityDragThatCanResizeWindow;
	[self addConstraint:constraint];
}

@end
