//
//  DTSideTabController.h
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 A Tabbed controller with one tab per view controller, presented with the tabs in a left or right side panel.
 */

@interface DTSideTabController : UIViewController

/**
 @name Managing the View Controllers
 */

/**
 An array of the root view controllers displayed by the tab bar interface.
 */
@property (nonatomic, strong) NSArray *viewControllers;

/**
 The view controller associated with the currently selected tab item.
 */
@property(nonatomic, assign) UIViewController *selectedViewController;

@end
