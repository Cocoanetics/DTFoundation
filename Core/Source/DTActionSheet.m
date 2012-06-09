//
//  DTActionSheet.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 08.06.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTActionSheet.h"

@implementation DTActionSheet
{
	id <UIActionSheetDelegate> _externalDelegate;
	
	NSMutableDictionary *_actionsPerIndex;
}

- (id)initWithTitle:(NSString *)title
{
	self = [super initWithTitle:title delegate:(id)self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
	
	if (self)
	{
		_actionsPerIndex = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title];
	
	if (block)
	{
		NSNumber *key = [NSNumber numberWithInt:retIndex];
		[_actionsPerIndex setObject:[block copy] forKey:key];
	}
	
	return retIndex;
}

- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setDestructiveButtonIndex:retIndex];
	
	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title
{
	NSInteger retIndex = [self addButtonWithTitle:title];
	[self setCancelButtonIndex:retIndex];
	
	return retIndex;
}

#pragma UIActionSheetDelegate (forwarded)

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	[_externalDelegate actionSheetCancel:actionSheet];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
	[_externalDelegate willPresentActionSheet:actionSheet];	
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
	[_externalDelegate didPresentActionSheet:actionSheet];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[_externalDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSNumber *key = [NSNumber numberWithInt:buttonIndex];
	
	DTActionSheetBlock block = [_actionsPerIndex objectForKey:key];
	
	if (block)
	{
		block();
	}
	
	[_externalDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
}


#pragma mark Properties

- (id <UIActionSheetDelegate>)delegate
{
	return _externalDelegate;
}

- (void)setDelegate:(id<UIActionSheetDelegate>)delegate
{
	if (delegate == (id)self)
	{
		[super setDelegate:(id)self];
	}
	else if (delegate == nil)
	{
		[super setDelegate:nil];
		_externalDelegate = nil;
	}
	else 
	{
		_externalDelegate = delegate;
	}
}

@end
