//
//  NSWindowController+DTViewControllerPresenting.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/1/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

typedef void (^DTPanelControllerPresentingCompletionBlock)(NSUInteger result);

@interface NSWindowController (DTPanelControllerPresenting)

@property (nonatomic, readonly, strong) NSWindowController *modalPanelController;

- (void)presentModalPanelController:(NSWindowController *)panelController;

- (void)dismissModalPanelController;

@end
