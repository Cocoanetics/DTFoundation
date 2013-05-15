//
//  UIViewController+DTSideTabController.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "UIViewController+DTSideTabController.h"

#import "DTSideTabItem.h"
#import <objc/runtime.h>

/**
 Enhancements for `UIViewController` for DTSideTabController
 */
@implementation UIViewController (DTSideTabController)

static char DTSideTabControllerItemKey;

- (void)setSideTabItem:(DTSideTabItem *)sideTabItem
{
	objc_setAssociatedObject(self, &DTSideTabControllerItemKey, sideTabItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DTSideTabItem *)sideTabItem
{
	return objc_getAssociatedObject(self, &DTSideTabControllerItemKey);
}

@end
