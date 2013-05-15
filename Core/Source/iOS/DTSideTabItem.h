//
//  DTSideTabItem.h
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 The DTSideTabItem class implements an item on a DTSideTabController's menu.
 */
@interface DTSideTabItem : NSObject

/**
 The text for the menu panel
 */
@property (nonatomic, copy) NSString *title;

/**
 The image for the menu panel
 */
@property (nonatomic) UIImage *image;

@end
