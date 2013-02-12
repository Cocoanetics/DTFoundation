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
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, panelController, OBJC_ASSOCIATION_RETAIN);
}


- (void)_didFinishDismissingPanel:(NSNotification *)notification
{
    // dismiss the panel controller
    objc_setAssociatedObject(self, &DTPresentedViewControllerKey, nil, OBJC_ASSOCIATION_RETAIN);
    
    // remove notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEndSheetNotification object:self.window];
}

- (void)dismissModalPanelController
{
	NSWindowController *windowController = self.modalPanelController;
	
	if (!windowController)
	{
		return;
	}
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // get notified if panel has been dismissed
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didFinishDismissingPanel:) name:NSWindowDidEndSheetNotification object:self.window];
        
        // dismiss the panel
        [windowController.window close];
        [NSApp endSheet:windowController.window];
    });
}

- (NSWindowController *)modalPanelController
{
	return objc_getAssociatedObject(self, &DTPresentedViewControllerKey);
}

@end
