//
//  UIImage+DTFoundation.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/8/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Methods to help with working with images.
 */
@interface UIImage (DTFoundation)

/**
 Mimicks the way images are drawn differently by UIImageView based on the set content mode.
 @param rect The rectangle to drawn in
 @param contentMode The content mode. Note that UIViewContentModeRedraw is treated the same as UIViewContentModeScaleToFill.
 */
- (void)drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode;

@end
