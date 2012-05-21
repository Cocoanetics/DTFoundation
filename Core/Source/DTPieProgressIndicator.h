//
//  DTPieProgressIndicator.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 16.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@interface DTPieProgressIndicator : UIView

@property (nonatomic, assign) CGFloat progressPercent;
@property (nonatomic, strong) UIColor *color;

+ (DTPieProgressIndicator *)pieProgressIndicator;



@end
