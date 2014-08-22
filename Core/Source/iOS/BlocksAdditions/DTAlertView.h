//
//  DTAlertView.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTWeakSupport.h"

// the block to execute when an alert button is tapped
typedef void (^DTAlertViewBlock)(void);

/**
 Wraps UIAlertView with support for blocks.
 */

@interface DTAlertView : NSObject

/**
 The receiver’s delegate.
 
 The delegate is not retained and must conform to the UIAlertViewDelegate protocol.
 */
@property (nonatomic, DT_WEAK_PROPERTY) id<UIAlertViewDelegate> delegate;

/**
 The number of buttons on the alert view. (read-only)
 */
@property (nonatomic, readonly) NSInteger numberOfButtons;

/**
 The wrapped UIAlertView. (read-only)
 */
@property (nonatomic, readonly) UIAlertView *wrappedAlertView;

/**
* Initializes the alert view. Add buttons and their blocks afterwards.
 @param title The alert title
 @param message The alert message
*/
- (id)initWithTitle:(NSString *)title message:(NSString *)message;

/**
 Convenience method for initializing an alert view.
 @param title The alert title
 @param message The alert message
 @param delegate The receiver’s delegate or nil if it doesn’t have a delegate.
 @param cancelButtonTitle The title of the cancel button or nil if there is no cancel button.
 @param otherButtonTitles The title of another button.
 @param ... Titles of additional buttons to add to the receiver, terminated with nil.
 */

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;

/**
 Adds a button to the alert view

 @param title The title of the new button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block;

/**
 Same as above, but for a cancel button.
 @param title The title of the cancel button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block;

/**
 Set a block to be run on alertViewCancel:.
 @param block The block to execute.
 */
- (void)setCancelBlock:(DTAlertViewBlock)block;

/**
 Displays the receiver using animation.
 */
- (void)show;

@end
