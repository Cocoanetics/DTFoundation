//
//  NSWindowController+DTViewControllerPresenting.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/1/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Enhancement for `NSWindowController` to present a sheet modally, similar to iOS
*/
@interface NSWindowController (DTPanelControllerPresenting)

/**-------------------------------------------------------------------------------------
 @name Presenting Modal Panels
 ---------------------------------------------------------------------------------------
 */

/**
 The current presented modal panel, or `nil` if there is no modal panel at present
 */
@property (nonatomic, readonly, strong) NSWindowController *modalPanelController;

/**
 Presents the panel modally
 @param panelController A window controller for the sheet, usually an NSWindowController with an NSPanel as window.
 */
- (void)presentModalPanelController:(NSWindowController *)panelController;

/**
 Dismisses a currently presented modal panel.
 */
- (void)dismissModalPanelController;

@end
