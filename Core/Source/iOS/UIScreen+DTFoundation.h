//
//  UIScreen+DTFoundation.h
//  DTFoundation
//
//  Created by Johannes Marbach on 16.10.17.
//  Copyright © 2017 Cocoanetics. All rights reserved.
//

/** DTFoundation enhancements for `UIView` */

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface UIScreen (DTFoundation)

- (UIInterfaceOrientation)orientation;

@end

#endif
