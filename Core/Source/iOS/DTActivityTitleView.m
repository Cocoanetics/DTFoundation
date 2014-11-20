//
//  DTActivityTitleView.m
//  DTFoundation
//
//  Created by Rene Pirringer on 12.09.12.
//  Copyright (c) 2012-2014 Cocoanetics. All rights reserved.
//

#import "DTActivityTitleView.h"


@implementation DTActivityTitleView
{
	UILabel *_titleLabel;
	UIActivityIndicatorView *_activityIndicator;
	CGFloat _margin;
	NSLayoutConstraint *_titleLabelMaxWidthContraint;
}

- (instancetype)init
{
	return [self initWithTitle:nil];
}

- (instancetype)initWithTitle:(NSString *)title
{
	self = [super init];
	
	if (self)
	{
		_titleLabel = [[UILabel alloc] init];
		_titleLabel.font = [self defaultFontForTitle];
		_titleLabel.text = title;
		_titleLabel.textColor = [UIColor blackColor];
		_titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_titleLabel.adjustsFontSizeToFitWidth = YES;
		_titleLabel.minimumFontSize = 10.0f;

		_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		_activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_titleLabel];
		[self addSubview:_activityIndicator];

		_margin = 50;

		// center title label
		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
			[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0],

		]];

		// set activity left of title view
		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-8.0],
			[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0],
		]];

	}
	return self;
}



- (void)layoutSubviews {


	CGFloat width = self.superview.frame.size.width - 2*(_margin + _activityIndicator.frame.size.width);
	if (width < 50) {
		width = 50;
	}
	if (_titleLabelMaxWidthContraint) {
		[self removeConstraint:_titleLabelMaxWidthContraint];
	}

	_titleLabelMaxWidthContraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:width],
	[self addConstraint:_titleLabelMaxWidthContraint];

}


#pragma mark - Properties

- (void)setBusy:(BOOL)busy
{
	if (busy)
	{
		[_activityIndicator startAnimating];
		_activityIndicator.hidden = NO;
	}
	else
	{
		[_activityIndicator stopAnimating];
		_activityIndicator.hidden = YES;
	}
	
	[self setNeedsLayout];
}

- (BOOL)busy
{
	return _activityIndicator.isAnimating;
}

- (void)setTitle:(NSString *)title
{
	_titleLabel.text = title;
	[self setNeedsLayout];
}

- (NSString *)title
{
	return _titleLabel.text;
}

- (UIFont *)defaultFontForTitle
{
	UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	return [font fontWithSize:font.pointSize+2.0f];
}

- (void)setTitleFont:(UIFont *)font {
	if (font) {
		_titleLabel.font = font;
	}
}

- (void)setMargin:(CGFloat)margin {
	_margin = margin;
	[self setNeedsLayout];
}

@end