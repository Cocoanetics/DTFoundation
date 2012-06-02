//
//  UIApplication+DTNetworkActivity.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/21/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@interface UIApplication (DTNetworkActivity)

- (void)pushActiveNetworkOperation;
- (void)popActiveNetworkOperation;

@end
