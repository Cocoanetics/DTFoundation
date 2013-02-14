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
static char DTPresentedViewControllerDismissalQueueKey;

@implementation NSWindowController (DTPanelControllerPresenting)

#pragma mark - Private Methods

// called as a result of the sheed ending notification
- (void)_didFinishDismissingPanel:(NSNotification *)notification
{
	// remove notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEndSheetNotification object:self.window];
	
	// dismiss the panel controller
	objc_setAssociatedObject(self, &DTPresentedViewControllerDismissalQueueKey, nil, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public Methods

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
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, panelController, OBJC_ASSOCIATION_RETAIN);
}

- (void)dismissModalPanelController
{
	NSWindowController *windowController = self.modalPanelController;
	
	if (!windowController)
	{
		NSLog(@"%s called, but nothing to dismiss", (const char *)__PRETTY_FUNCTION__);
		return;
	}
	
	// retain it in the dismissal queue so that we can present a new one right after the out animation has finished
	objc_setAssociatedObject(self, &DTPresentedViewControllerDismissalQueueKey, windowController, OBJC_ASSOCIATION_RETAIN);
	
	// get notified if panel has been dismissed
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didFinishDismissingPanel:) name:NSWindowDidEndSheetNotification object:self.window];
	
	// dismiss the panel
	[windowController.window close];
	[NSApp endSheet:windowController.window];
	
	// free the reference
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, nil, OBJC_ASSOCIATION_RETAIN);
}

- (NSWindowController *)modalPanelController
{
	return objc_getAssociatedObject(self, &DTPresentedViewControllerKey);
}

@end
