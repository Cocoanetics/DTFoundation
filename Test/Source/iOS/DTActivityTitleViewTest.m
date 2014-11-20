//
// Created by Rene Pirringer
// Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DTActivityTitleView.h"


@interface DTActivityTitleViewTest : XCTestCase
@end

@implementation DTActivityTitleViewTest {
	DTActivityTitleView *_activityTitleView;
}

- (void)setUp {
	_activityTitleView = [[DTActivityTitleView alloc] initWithTitle:@"Test"];
	XCTAssertNotNil(_activityTitleView);

	_activityTitleView.frame = CGRectMake(0, 0, 320, 44);
	[_activityTitleView layoutSubviews];
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	[window addSubview:_activityTitleView];
	XCTAssertNotNil(window);
	[window makeKeyAndVisible];
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
		[CATransaction commit];
	}
}



- (void)tearDown {
	[_activityTitleView removeFromSuperview];
}

- (UILabel *)titleLabel {
	for (UIView *view in _activityTitleView.subviews) {
		if ([view isKindOfClass:[UILabel class]]) {
			return (UILabel *) view;
		}
	}
	return nil;
}


- (UIActivityIndicatorView *)activityIndicatorView {
	for (UIView *view in _activityTitleView.subviews) {
		if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
			return (UIActivityIndicatorView *) view;
		}
	}
	return nil;
}

- (void) testNavigationTitleIsCenter {

	UILabel *titleLabel = [self titleLabel];

	XCTAssertNotNil(titleLabel);
	XCTAssert(floor(titleLabel.center.x) == floor(_activityTitleView.center.x), @"titleLabel.center.x (%@) is not equal to _activityTitleView.center.x (%@)", @(titleLabel.center.x), @(_activityTitleView.center.x));
}


- (void)testActivityPosition {
	_activityTitleView.busy = YES;
	UIActivityIndicatorView *activityIndicatorView = [self activityIndicatorView];

	UILabel *titleLabel = [self titleLabel];

	XCTAssertNotNil(activityIndicatorView);
	CGFloat expectedX = titleLabel.frame.origin.x - 8 - activityIndicatorView.frame.size.width;
	XCTAssert(activityIndicatorView.frame.origin.x == expectedX, @"activityIndicatorView.frame.origin.x (%@) is not equal %@", @(activityIndicatorView.frame.origin.x), @(expectedX));

}

- (void)testActivityBusy {
	UIActivityIndicatorView *activityIndicatorView = [self activityIndicatorView];
	XCTAssertTrue(activityIndicatorView.hidden);
	_activityTitleView.busy = YES;
	XCTAssertFalse(activityIndicatorView.hidden);
	_activityTitleView.busy = NO;
	XCTAssertTrue(activityIndicatorView.hidden);
}

- (void)testTitleDefaultFont {
	UILabel *titleLabel = [self titleLabel];

	XCTAssert(titleLabel.font.pointSize == 17.0, @"Expected font size of 17pt but was %@", @(titleLabel.font.pointSize));

}

- (void)testCustomFont {

	UIFont *font = [UIFont systemFontOfSize:20.0];
	[_activityTitleView setTitleFont:font];

	UILabel *titleLabel = [self titleLabel];

	XCTAssert(titleLabel.font == font, @"Title font is not the custom font that was set");

}


- (void)testActivityWithLongTitle {
	_activityTitleView.title = @"Test Test Test Test Test Test Test Test Test Test";

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
		[CATransaction commit];
	}
	UILabel *titleLabel = [self titleLabel];

	XCTAssert(titleLabel.frame.origin.x > 0, @"titleLabel.frame.origin.x (%@) is less than 0", @(titleLabel.frame.origin.x));

}

@end