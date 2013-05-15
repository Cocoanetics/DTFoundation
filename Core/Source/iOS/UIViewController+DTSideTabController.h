//
//  UIViewController+DTSideTabController.h
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@class DTSideTabItem;

@interface UIViewController (DTSideTabController)

/**
 The side tab item for the receiver which is used by DTSideTabController
 */
@property (nonatomic, strong) DTSideTabItem *sideTabItem;

@end
