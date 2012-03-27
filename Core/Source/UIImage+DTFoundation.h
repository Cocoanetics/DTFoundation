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

/**
 @name Working with Tiles
 */
 
/**
 Cuts out a tile at the given row and column
 */
- (UIImage *)tileImageAtColumn:(NSUInteger)column ofColumns:(NSUInteger)columns row:(NSUInteger)row ofRows:(NSUInteger)rows;

/**
 Cuts out a tile at the given clip rect relative to the bounds
 */
- (UIImage *)tileImageInClipRect:(CGRect)clipRect inBounds:(CGRect)bounds scale:(CGFloat)scale;


@end
