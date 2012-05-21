//
//  DTSmartPagingScrollView.h
//  DTSmartPhotoView
//
//  Created by Stefan Gugarel on 5/11/12.
//  Copyright (c) 2012 Stefan Gugarel. All rights reserved.
//

@class DTSmartPagingScrollView;

@protocol DTSmartPagingScrollViewDatasource <NSObject>

- (NSUInteger)numberOfPagesInSmartPagingScrollView:(DTSmartPagingScrollView *)smartPagingScrollView;
- (UIView *)smartPagingScrollView:(DTSmartPagingScrollView *)smartPagingScrollView viewForPageAtIndex:(NSUInteger)index;

@optional
- (void)smartPagingScrollView:(DTSmartPagingScrollView *)smartPagingScrollView didScrollToPageAtIndex:(NSUInteger)index;

@end


@interface DTSmartPagingScrollView : UIScrollView

@property (nonatomic, assign) id <DTSmartPagingScrollViewDatasource> pageDatasource;
@property (nonatomic, assign) NSUInteger currentPageIndex;

- (void)reloadData;
- (NSRange)rangeOfVisiblePages;
- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated;

@end
