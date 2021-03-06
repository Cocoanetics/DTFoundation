//
//  UIViewController+DTSidePanelController.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/24/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

/**
 Methods to enhance `UIViewController` for use with DTSidePanelController
 */

@class DTSidePanelController;

@interface UIViewController (DTSidePanelController)

/**
 Returns the nearest DTSidePanelController in the view controller hierarchy that is presenting the receiver.
 
 If it is not embedded in a side panel controller then this property is `nil`.
 @returns The side panel controller
 */
- (DTSidePanelController *)sidePanelController;

@end

#endif
