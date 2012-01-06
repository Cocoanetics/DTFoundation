//
//  UIView+DTFoundation.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 12/23/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

/** DTFoundation enhancements for `UIView` */

@interface UIView (DTFoundation)

/**---------------------------------------------------------------------------------------
 * @name Getting Snapshot Images 
 *  ---------------------------------------------------------------------------------------
 */

/** Creates a snapshot of the receiver.
 
 @return Returns a bitmap image with the same contents and dimensions as the receiver.
 */
- (UIImage *)snapshotImage;

/**---------------------------------------------------------------------------------------
 * @name Rounded Corners
 *  ---------------------------------------------------------------------------------------
 */

/** Sets the corner attributes of the receiver's layer.
 
 The advantage of using this method is that you do not need to import the QuartzCore headers just for setting the corners.
 @param radius The corner radius.
 @param width The width of the border line.
 @param color The color to be used for the border line. Can be `nil` to leave it unchanged.
 */
- (void)setRoundedCornersWithRadius:(CGFloat)radius width:(CGFloat)width color:(UIColor *)color;

@end
