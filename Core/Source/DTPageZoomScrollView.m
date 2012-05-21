//
//  DTPageZoomScrollView.m
//  DTSmartPhotoView
//
//  Created by Stefan Gugarel on 5/11/12.
//  Copyright (c) 2012 Stefan Gugarel. All rights reserved.
//

#import "DTPageZoomScrollView.h"

#define ZOOM_SCALE_STEP 0.5f

#define IMAGE_MINIMIZE_ZOOM_FACTOR 0.90f


NSString * const DTPageZoomScrollViewDidZoomNotification = @"DTPageZoomScrollViewDidZoomNotification";

@implementation DTPageZoomScrollView
{
    UIView *_viewToZoom;
    CGSize _originalViewSize;
    
    BOOL _needsMinMaxSetting;
    
    // after initial layout this enables preserving the senter on setFrame
    BOOL _shouldRestoreCenterOnBoundsChange;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    
    CGFloat _oldZoomScale;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.delegate = self;
        
        // double tap gesture recognizer
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        _tapGestureRecognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:_tapGestureRecognizer];
        
        _oldZoomScale = CGFLOAT_MAX;
        
        //[self.panGestureRecognizer addTarget:self action:@selector(pinched:)];
    }
    return self;
}


- (void)setMaxMinZoomScalesForCurrentBounds
{
    if (self.bounds.size.width==0 || self.bounds.size.height == 0)
    {
        _needsMinMaxSetting = YES;
        return;
    }
    
    if (CGSizeEqualToSize(_originalViewSize, CGSizeZero))
    {
        // no image loaded yet
        return;
    }
    
    CGSize boundsSize = self.bounds.size;
    
    //  CGFloat scaleToFitHeight = boundsSize.height / _originalViewSize.height;
    CGFloat scaleToFitWidth =  boundsSize.width / _originalViewSize.width;
    
    // CGFloat scale = MIN(scaleToFitHeight, scaleToFitWidth);
    CGFloat scale = scaleToFitWidth;
    
    
    self.minimumZoomScale = scale;
    
    //    CGFloat diffWidth = fabs(_originalViewSize.width - boundsSize.width);
    //    CGFloat diffHeight = fabs(_originalViewSize.height - boundsSize.height);
    //    
    //    // set zoomScale to aspectFill image
    //    if (diffWidth < diffHeight)
    //    {
    //        self.minimumZoomScale =   boundsSize.width / _originalViewSize.width;
    //    }
    //    else
    //    {
    //        self.minimumZoomScale =  boundsSize.height / _originalViewSize.height;
    //    }
    
    self.maximumZoomScale = self.minimumZoomScale * 2.0f;
    
    self.zoomScale = self.minimumZoomScale;
    
    _needsMinMaxSetting = NO;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    
    if (boundsSize.width==0 || boundsSize.height == 0)
    {
        return;
    }
    
    CGRect frameToCenter = _viewToZoom.frame;
    
    // center photo horizontally
    if (frameToCenter.size.width < boundsSize.width)
    {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else
    {
        frameToCenter.origin.x = 0;
    }
    
    if (frameToCenter.size.height < boundsSize.height)
    {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else 
    {
        frameToCenter.origin.y = 0;
    }
    
    _viewToZoom.frame = frameToCenter;
    
    if (_needsMinMaxSetting)
    {
        [self setMaxMinZoomScalesForCurrentBounds];
    }
    
    _shouldRestoreCenterOnBoundsChange = YES;
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _viewToZoom;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
    if (_oldZoomScale <= self.minimumZoomScale * IMAGE_MINIMIZE_ZOOM_FACTOR && self.zoomScale == self.minimumZoomScale)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DTPageZoomScrollViewDidZoomNotification object:self userInfo:nil];
    }
    
    _oldZoomScale = self.zoomScale;
}

#pragma mark Properties

- (void)setViewToZoom:(UIView *)viewToZoom
{
    if (_viewToZoom != viewToZoom)
    {
        _viewToZoom = viewToZoom;
        
        self.zoomScale = 1.0;
        self.contentSize = viewToZoom.bounds.size;
        
        _viewToZoom.frame = viewToZoom.bounds;
        _originalViewSize = _viewToZoom.bounds.size;
        
        [self addSubview:_viewToZoom];
        
        [self setMaxMinZoomScalesForCurrentBounds];
    }
}

// returns the center point, in image coordinate space, to try to restore after rotation. 
- (CGPoint)pointToCenterAfterRotation
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    return [self convertPoint:boundsCenter toView:_viewToZoom];
}

// returns the zoom scale to attempt to restore after rotation. 
- (CGFloat)scaleToRestoreAfterRotation
{
    CGFloat contentScale = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (contentScale <= self.minimumZoomScale + FLT_EPSILON)
    {
        contentScale = 0;
    }
    
    return contentScale;
}

- (CGPoint)maximumContentOffset
{
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset
{
    return CGPointZero;
}

// Adjusts content offset and scale to try to preserve the old zoomscale and center.
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale
{    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    self.zoomScale = MIN(self.maximumZoomScale, MAX(self.minimumZoomScale, oldScale));
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:oldCenter fromView:_viewToZoom];
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0, 
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    offset.x = MAX(minOffset.x, MIN(maxOffset.x, offset.x));
    offset.y = MAX(minOffset.y, MIN(maxOffset.y, offset.y));
    self.contentOffset = offset;
}


- (void)setFrame:(CGRect)frame
{
    _oldZoomScale = CGFLOAT_MAX;
    
    CGPoint centerToRestore = [self pointToCenterAfterRotation];
    CGFloat scaleToRestore = [self scaleToRestoreAfterRotation];
    
    [super setFrame:frame];
    
    if (_shouldRestoreCenterOnBoundsChange)
    {
        [self setMaxMinZoomScalesForCurrentBounds];
        [self restoreCenterPoint:centerToRestore scale:scaleToRestore];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    _needsMinMaxSetting = YES;
}

#pragma mark - Gesture Recognizers

- (void)doubleTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    
    if (self.zoomScale  + ZOOM_SCALE_STEP < self.maximumZoomScale)
    {
        CGPoint location = [tapGestureRecognizer locationInView:_viewToZoom];
        
        CGSize zoomSize = _viewToZoom.bounds.size;
        zoomSize.width /= self.zoomScale + ZOOM_SCALE_STEP;
        zoomSize.height /= self.zoomScale + ZOOM_SCALE_STEP;
        
        CGRect targetRect = CGRectMake(location.x - zoomSize.width/2.0, location.y - zoomSize.height/2.0, zoomSize.width/2, zoomSize.height/2);
        [self zoomToRect:targetRect animated:YES];
        
    }
    else
    {
        CGRect zoomOutRect = CGRectMake(0, 0, _viewToZoom.bounds.size.width , _viewToZoom.bounds.size.height);
        [self zoomToRect:zoomOutRect animated:YES];
    }
}

//- (void)handlePinch:(UIPinchGestureRecognizer *)pinchGestureRecognizer
//{
//    
//    
//    // only send notification if gesture has ended
//    if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded)
//    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:DTPageZoomScrollViewDidZoomNotification object:self userInfo:nil];
//    }
//    
//    //[super handlePinch:pinchGestureRecognizer];
//}


@synthesize viewToZoom = _viewToZoom;

@end
