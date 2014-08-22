//
//  DTActionSheet.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 08.06.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTWeakSupport.h"

// the block to execute when an option button is tapped
typedef void (^DTActionSheetBlock)(void);

/**
 Wraps UIActionSheet with support for blocks.
 */

@interface DTActionSheet : NSObject

/**
 The receiver’s delegate.
 
 The delegate is not retained and must conform to the UIActionSheetDelegate protocol.
 */
@property (nonatomic, DT_WEAK_PROPERTY) id<UIActionSheetDelegate> delegate;

/**
 The number of buttons on the alert view. (read-only)
 */
@property (nonatomic, readonly) NSInteger numberOfButtons;

/**
 The wrapped UIAlertView. (read-only)
 */
@property (nonatomic, readonly) UIActionSheet *wrappedActionSheet;

/**
 Initializes the action sheet using the specified title. 
 @param title The title
 */
- (id)initWithTitle:(NSString *)title;

/**
 Convenience method for initializing an action sheet.
 @param title The title
 @param delegate The receiver’s delegate or nil if it doesn’t have a delegate.
 @param cancelButtonTitle The title of the cancel button or nil if there is no cancel button.
 @param destructiveButtonTitle The title of the destructive button or nil if there is no dectructive button.
 @param otherButtonTitles The title of another button.
 @param ... Titles of additional buttons to add to the receiver, terminated with nil.
 */

- (id)initWithTitle:(NSString *)title delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;

/**
 Adds a custom button to the action sheet.
 @param title The title of the new button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
*/ 
- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block;

/**
 Adds a custom destructive button to the action sheet.
 
 Since there can only be one destructive button a previously marked destructive button becomes a normal button.
 @param title The title of the new button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */ 
- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block;

/**
 Adds a custom cancel button to the action sheet.
 
 Since there can only be one cancel button a previously marked cancel button becomes a normal button.
 @param title The title of the new button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block;

/**
 Adds a custom cancel button to the action sheet.
 
 Since there can only be one cancel button a previously marked cancel button becomes a normal button.
 @param title The title of the new button.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */ 
- (NSInteger)addCancelButtonWithTitle:(NSString *)title;

- (void)showFromToolbar:(UIToolbar *)view;
- (void)showFromTabBar:(UITabBar *)view;
- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated NS_AVAILABLE_IOS(3_2);
- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated NS_AVAILABLE_IOS(3_2);
- (void)showInView:(UIView *)view;

@end
