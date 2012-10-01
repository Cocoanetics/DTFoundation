//
//  NSWindow+DTViewControllerPresenting.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/1/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "objc/runtime.h"

#import "NSWindowController+DTPanelControllerPresenting.h"

static char DTPresentedViewControllerKey;

@implementation NSWindowController (DTPanelControllerPresenting)

- (void)presentModalPanelController:(NSWindowController *)panelController
{
	NSWindowController *windowController = self.modalPanelController;
	
	if (windowController)
	{
		NSLog(@"Already presenting %@, cannot modally present another panel", NSStringFromClass([windowController class]));
		return;
	}

	[NSApp beginSheet:panelController.window modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	
	// retain the panel view controller
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, panelController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dismissModalPanelController
{
	NSWindowController *windowController = self.modalPanelController;
	
	if (!windowController)
	{
		return;
	}

	// slide out
	[NSApp endSheet:windowController.window];
	[windowController.window close];
	
	// free the panel view controller
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSWindowController *)modalPanelController
{
	return objc_getAssociatedObject(self, &DTPresentedViewControllerKey);
}

@end
