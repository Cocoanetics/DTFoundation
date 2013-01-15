//
//  NSView+DTAutoLayout.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 26.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Useful shortcuts for auto layout on Mac
 */

@interface NSView (DTAutoLayout)

/**
 Creates and adds a layout contraint to the receiver that enforces a minimum width.
 @param width The width to enforce
 */
- (void)addLayoutConstraintWithWidthGreaterOrEqualThan:(CGFloat)width;

@end
