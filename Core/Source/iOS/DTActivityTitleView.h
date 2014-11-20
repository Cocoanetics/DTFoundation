//
//  DTActivityTitleView.h
//  DTFoundation
//
//  Created by Rene Pirringer
//  Copyright (c) 2012-2014 Cocoanetics. All rights reserved.
//

/**
 Alternative view for showing titles with a configurable activity indicator
 instead of default title view in navigationItem.
 */
@interface DTActivityTitleView : UIView

/**
 Initializes the title view using the specified title.
 @param title The title
 */
- (instancetype)initWithTitle:(NSString *)title;

/**
 Initializes the title view with an empty title
 @param title The title
 */
- (instancetype)init;


/**
* Sets a custom font for the title
*/
- (void)setTitleFont:(UIFont *)font;

/**
 Title that is shown
 */
@property (nonatomic, copy) NSString *title;

/**
 When busy is set to YES the activity indicator starts spinning
 When set to NO the activity indicator stops spinning
 */
@property (nonatomic, assign) BOOL busy;


/**
* Sets a custom margin that is applied left and right of the titleView
* The default value is 50
* You can use this value to avoid overlapping of the title with bar button items, if you have more than one
*/
- (void)setMargin:(CGFloat)margin;

@end
