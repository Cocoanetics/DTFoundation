//
//  DTAlertView.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^DTAlertViewBlock)(NSInteger buttonIndex);

@interface DTAlertView : UIAlertView

/**
* Initializes the alert view (same parameters as UIAlertView except delegate)
*/
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
* Shows DTAlertView and calls @see DTAlertViewBlock when user tapped one of the provided button(s)
*/
- (void)showWithUserInteraction:(DTAlertViewBlock)userInteraction;

@end
