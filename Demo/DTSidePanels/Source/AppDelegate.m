//
//  AppDelegate.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "AppDelegate.h"

#import "DTSidePanelController.h"
#import "TableViewController.h"
#import "ModalPanelViewController.h"
#import "DemoViewController.h"
#import "LoggingNavigationController.h"

@interface AppDelegate () <DTSidePanelControllerDelegate>

@end

@implementation AppDelegate
{
	DTSidePanelController *_sidePanelController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// set up panel for left side
	UIViewController *leftVC = [[TableViewController alloc] init];
	leftVC.navigationItem.title = @"Left";
	LoggingNavigationController *leftNav = [[LoggingNavigationController alloc] initWithRootViewController:leftVC];
	
	// set up panel for right side
	ModalPanelViewController *rightVC = [[ModalPanelViewController alloc] initWithNibName:@"ModalPanelViewController" bundle:nil];
	rightVC.navigationItem.title = @"Right";
	LoggingNavigationController *rightNav = [[LoggingNavigationController alloc] initWithRootViewController:rightVC];
	
	// set up center panel
	UIViewController *centerVC = [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
	centerVC.navigationItem.title = @"Center";
	
	// create a panel controller as root
	_sidePanelController = [[DTSidePanelController alloc] init];
    
    // create a left and right "Hamburger" icon on center VC's navigationItem
	UIImage *hamburgerIcon = [UIImage imageNamed:@"toolbar-icon-menu"];
	centerVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:hamburgerIcon style:UIBarButtonItemStyleBordered target:_sidePanelController action:@selector(toggleLeftPanel:)];
	centerVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:hamburgerIcon style:UIBarButtonItemStyleBordered target:_sidePanelController action:@selector(toggleRightPanel:)];
	LoggingNavigationController *centerNav = [[LoggingNavigationController alloc] initWithRootViewController:centerVC];
	
	// left panel has fixed width, right panel width is variable
	[_sidePanelController setWidth:200 forPanel:DTSidePanelControllerPanelLeft animated:NO];
	
	// set the panels on the controller
	_sidePanelController.leftPanelController = leftNav;
	_sidePanelController.centerPanelController = centerNav;
	_sidePanelController.rightPanelController = rightNav;
	_sidePanelController.sidePanelDelegate = self;

	self.window.rootViewController = _sidePanelController;
	[self.window makeKeyAndVisible];
	
	return YES;
}


#pragma mark - DTSidePanelControllerDelegate

- (BOOL)sidePanelController:(DTSidePanelController *)sidePanelController shouldAllowClosingOfSidePanel:(DTSidePanelControllerPanel)sidePanel
{
	if (sidePanel == DTSidePanelControllerPanelRight)
	{
		UINavigationController *navController = (UINavigationController *)sidePanelController.rightPanelController;
		ModalPanelViewController *controller = (ModalPanelViewController *)[[navController viewControllers] objectAtIndex:0];
		
		return [controller allowClosing];
	}
	
	return YES;
}

@end
