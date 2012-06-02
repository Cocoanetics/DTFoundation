//
//  DTPageZoomScrollView.h
//  DTSmartPhotoView
//
//  Created by Stefan Gugarel on 5/11/12.
//  Copyright (c) 2012 Stefan Gugarel. All rights reserved.
//

extern NSString * const DTPageZoomScrollViewDidZoomNotification;


@interface DTPageZoomScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *viewToZoom;

- (void)setMaxMinZoomScalesForCurrentBounds;

@end
