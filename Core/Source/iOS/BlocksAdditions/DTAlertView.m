//
//  DTAlertView.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTAlertView.h"

@interface DTAlertView() <UIAlertViewDelegate>

@end

@implementation DTAlertView
{
    UIAlertView *_alertView;
    
    DTAlertView *_strongSelf;
    
	NSMutableDictionary *_actionsPerIndex;

	DTAlertViewBlock _cancelBlock;
}

// designated initializer
- (id)init
{
    self = [super init];
    if (self)
    {
        _actionsPerIndex = [[NSMutableDictionary alloc] init];
        _alertView = [[UIAlertView alloc] init];
        _alertView.delegate = self;
        _strongSelf = self;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    return [self initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	self = [self init];
	if (self)
	{
        _alertView.title = title;
        _alertView.message = message;
        
        if (otherButtonTitles != nil) {
            [_alertView addButtonWithTitle:otherButtonTitles];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *title = nil;
            while( (title = va_arg(args, NSString *)) ) {
                [_alertView addButtonWithTitle:title];
            }
            va_end(args);
        }
        if (cancelButtonTitle) {
            [self addCancelButtonWithTitle:cancelButtonTitle block:nil];
        }
        
        self.delegate = delegate;
	}
	return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block
{
	NSInteger retIndex = [_alertView addButtonWithTitle:title];

	if (block)
	{
		NSNumber *key = [NSNumber numberWithInteger:retIndex];
		[_actionsPerIndex setObject:[block copy] forKey:key];
	}

	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[_alertView setCancelButtonIndex:retIndex];

	return retIndex;
}

- (void)setCancelBlock:(DTAlertViewBlock)block
{
	_cancelBlock = block;
}

- (void)show
{
    [_alertView show];
}

# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSNumber *key = [NSNumber numberWithInteger:buttonIndex];
    
	DTAlertViewBlock block = [_actionsPerIndex objectForKey:key];
	if (block)
	{
		block();
	}

	if ([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
	{
		[self.delegate alertView:_alertView clickedButtonAtIndex:buttonIndex];
	}
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
	if (_cancelBlock)
	{
		_cancelBlock();
	}

	if ([self.delegate respondsToSelector:@selector(alertViewCancel:)])
	{
		[self.delegate alertViewCancel:_alertView];
	}
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
	if ([self.delegate respondsToSelector:@selector(willPresentAlertView:)])
	{
		[self.delegate willPresentAlertView:_alertView];
	}
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
	if ([self.delegate respondsToSelector:@selector(didPresentAlertView:)])
	{
		[self.delegate didPresentAlertView:_alertView];
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([self.delegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)])
	{
		[self.delegate alertView:_alertView willDismissWithButtonIndex:buttonIndex];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([self.delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)])
	{
		[self.delegate alertView:_alertView didDismissWithButtonIndex:buttonIndex];
	}
    _alertView = nil;
    _strongSelf = nil;
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
	if ([self.delegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)])
	{
		return [self.delegate alertViewShouldEnableFirstOtherButton:_alertView];
	}

	return YES;
}

# pragma mark - properties

- (NSInteger)numberOfButtons
{
    return _alertView.numberOfButtons;
}

- (UIAlertView *)wrappedAlertView
{
    return _alertView;
}


@end
