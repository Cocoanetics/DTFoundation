//
//  DTSidePanelController.h
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

// types of panels
typedef enum
{
	DTSidePanelControllerPanelCenter = 0,
	DTSidePanelControllerPanelLeft,
	DTSidePanelControllerPanelRight
} DTSidePanelControllerPanel;


/**
 A container view controller with a main view and one or two optional panels that appear when moving the main view to the left or right side. Having a center panel is mandatory the left and right panels are optional.
 */
@interface DTSidePanelController : UIViewController

/**
 @name Showing Panels
 */

/**
 Shows the specified panel
 @paramenter panel The panel to present
 @parameter animated Whether the presentation should be animated
 */
- (void)presentPanel:(DTSidePanelControllerPanel)panel animated:(BOOL)animated;


/**
 Returns the currently panel that is visible for the most part, i.e. that the user is focussing on
 */
- (DTSidePanelControllerPanel)presentedPanel;

/**
 @name Customizing Appearance
 */

/**
 Sets the display width for the given panel. The center panel is center-aligned, the left panel is left-aligned and the right panel is right-aligned
 */
//- (void)setWidth:(CGFloat)width forPanel:(DTSidePanelControllerPanel)panel;

/**
 @name Properties
 */

/**
 The view controller controlling the center panel
 */
@property (nonatomic, strong) UIViewController *centerPanelController;

/**
 The view controller controlling the panel that appears on the left side below the main view
 */
@property (nonatomic, strong) UIViewController *leftPanelController;

/**
 The view controller controlling the panel that appears on the left side below the main view
 */
@property (nonatomic, strong) UIViewController *rightPanelController;

@end
