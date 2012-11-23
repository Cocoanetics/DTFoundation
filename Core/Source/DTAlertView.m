//
//  DTAlertView.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTAlertView.h"

@interface DTAlertView() <UIAlertViewDelegate>

@end

@implementation DTAlertView
{
	DTAlertViewBlock _userInteraction;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... 
{
	self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
	if (self)
	{
		// add other button titles via argument list
		if (otherButtonTitles)
		{
			[self addButtonWithTitle:otherButtonTitles];
			va_list args;
			va_start(args, otherButtonTitles);
			NSString * title = nil;
			while((title = va_arg(args, NSString*))) {
				[self addButtonWithTitle:title];
			}
			va_end(args);
		}
	}
	
	return self;
}

- (void)showWithUserInteraction:(DTAlertViewBlock)userInteraction
{
	_userInteraction = userInteraction;

	[super show];
}


# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	_userInteraction(buttonIndex);
}

@end
