//
//  DTActionSheet.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 08.06.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTActionSheet.h"

@interface DTActionSheet () <UIActionSheetDelegate>

@end

@implementation DTActionSheet
{
	UIActionSheet *_actionSheet;
    
    DTActionSheet *_strongSelf;
	
	NSMutableDictionary *_actionsPerIndex;
	
	// lookup bitmask what delegate methods are implemented
	struct 
	{
		unsigned int delegateSupportsActionSheetCancel:1;
		unsigned int delegateSupportsWillPresentActionSheet:1;
		unsigned int delegateSupportsDidPresentActionSheet:1;
		unsigned int delegateSupportsWillDismissWithButtonIndex:1;
		unsigned int delegateSupportsDidDismissWithButtonIndex:1;
		unsigned int delegateSupportsClickedButtonAtIndex:1;
	} _delegateFlags;
	
	BOOL _isDeallocating;
}

// designated initializer
- (id)init
{
    self = [super init];
    if (self)
    {
        _actionsPerIndex = [[NSMutableDictionary alloc] init];
        _actionSheet = [[UIActionSheet alloc] init];
        _actionSheet.delegate = self;
        _strongSelf = self;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title
{
    return [self initWithTitle:title delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
}

- (id)initWithTitle:(NSString *)title delegate:(id<UIActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	self = [self init];
	if (self) 
	{
        _actionSheet.title = title;
        
        if (otherButtonTitles != nil) {
            [_actionSheet addButtonWithTitle:otherButtonTitles];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *title = nil;
            while( (title = va_arg(args, NSString *)) ) {
                [_actionSheet addButtonWithTitle:title];
            }
            va_end(args);
        }
        
        if (destructiveButtonTitle) {
            [self addDestructiveButtonWithTitle:destructiveButtonTitle block:nil];
        }
        if (cancelButtonTitle) {
            [self addCancelButtonWithTitle:cancelButtonTitle block:nil];
        }

        self.delegate = delegate;
	}
	
	return self;
}

- (void)dealloc
{
	_isDeallocating = YES;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [_actionSheet addButtonWithTitle:title];
	
	if (block)
	{
		NSNumber *key = [NSNumber numberWithInteger:retIndex];
		[_actionsPerIndex setObject:[block copy] forKey:key];
	}
	
	return retIndex;
}

- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[_actionSheet setDestructiveButtonIndex:retIndex];
	
	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title
{
    return [self addCancelButtonWithTitle:title block:nil];
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[_actionSheet setCancelButtonIndex:retIndex];
	
	return retIndex;
}

- (void)showFromToolbar:(UIToolbar *)view
{
    [_actionSheet showFromToolbar:view];
}

- (void)showFromTabBar:(UITabBar *)view
{
    [_actionSheet showFromTabBar:view];
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated
{
    [_actionSheet showFromBarButtonItem:item animated:animated];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    [_actionSheet showFromRect:rect inView:view animated:animated];
}

- (void)showInView:(UIView *)view
{
    [_actionSheet showInView:view];
}

#pragma mark - UIActionSheetDelegate (forwarded)

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	if (_delegateFlags.delegateSupportsActionSheetCancel)
	{
		[self.delegate actionSheetCancel:actionSheet];
	}
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
	if (_delegateFlags.delegateSupportsWillPresentActionSheet)
	{
		[self.delegate willPresentActionSheet:actionSheet];
	}
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
	if (_delegateFlags.delegateSupportsDidPresentActionSheet)
	{
		[self.delegate didPresentActionSheet:actionSheet];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (_delegateFlags.delegateSupportsWillDismissWithButtonIndex)
	{
		[self.delegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (_delegateFlags.delegateSupportsDidDismissWithButtonIndex)
	{
		[self.delegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
	}
    
    _actionSheet = nil;
    _strongSelf = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSNumber *key = [NSNumber numberWithInteger:buttonIndex];
	
	DTActionSheetBlock block = [_actionsPerIndex objectForKey:key];
	
	if (block)
	{
		block();
	}

	if (_delegateFlags.delegateSupportsClickedButtonAtIndex)
	{
		[self.delegate actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
	}
}

#pragma mark - Properties

- (void)setDelegate:(id <UIActionSheetDelegate>)delegate
{
	_delegate = delegate;
	
	// wipe
	memset(&_delegateFlags, 0, sizeof(_delegateFlags));
	
	// set flags according to available methods in delegate
	if ([_delegate respondsToSelector:@selector(actionSheetCancel:)])
	{
		_delegateFlags.delegateSupportsActionSheetCancel = YES;
	}

	if ([_delegate respondsToSelector:@selector(willPresentActionSheet:)])
	{
		_delegateFlags.delegateSupportsWillPresentActionSheet = YES;
	}

	if ([_delegate respondsToSelector:@selector(didPresentActionSheet:)])
	{
		_delegateFlags.delegateSupportsDidPresentActionSheet = YES;
	}

	if ([_delegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)])
	{
		_delegateFlags.delegateSupportsWillDismissWithButtonIndex = YES;
	}

	if ([_delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)])
	{
		_delegateFlags.delegateSupportsDidDismissWithButtonIndex = YES;
	}
	
	if ([_delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)])
	{
		_delegateFlags.delegateSupportsClickedButtonAtIndex = YES;
	}
}

- (UIActionSheet *)wrappedActionSheet
{
    return _actionSheet;
}

- (NSInteger)numberOfButtons
{
    return _actionSheet.numberOfButtons;
}

@end
