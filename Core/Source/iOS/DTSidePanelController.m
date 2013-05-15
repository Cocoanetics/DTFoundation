//
//  DTSidePanelController.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTSidePanelController.h"

#import <QuartzCore/QuartzCore.h>

@interface DTSidePanelController ()

@end

@implementation DTSidePanelController
{
	UIView *_centerBaseView;
	UIView *_leftBaseView;
	UIView *_rightBaseView;
	
	CGFloat _minimumVisibleCenterWidth;
	CGPoint _lastTranslation;
	
	NSTimeInterval _lastMoveTimestamp;
	CGFloat _minimumAnimationMomentum;
	CGFloat _maximumAnimationMomentum;
}


- (void)loadView
{
	// set up the base view
	CGRect frame = [[UIScreen mainScreen] applicationFrame];
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.backgroundColor = [UIColor blackColor];
	view.autoresizesSubviews = YES;
	
	self.view = view;
	
	_minimumVisibleCenterWidth = 50;
	_minimumAnimationMomentum = 700;
	_maximumAnimationMomentum = 2000;
}

- (void)viewWillAppear:(BOOL)animated
{
	NSAssert(_centerPanelController, @"Must have a center panel controller");
	
	[super viewWillAppear:animated];
}

- (void)_sortPanels
{
	if (_centerBaseView)
	{
		[self.view bringSubviewToFront:_centerBaseView];
	}
	
	if ([self _rightPanelVisibleWidth]==0)
	{
		[self.view sendSubviewToBack:_rightBaseView];
	}
	
	if ([self _leftPanelVisibleWidth]==0)
	{
		[self.view sendSubviewToBack:_leftBaseView];
	}
}

#pragma mark - Calculations

- (CGFloat)_leftPanelVisibleWidth
{
	if (!_leftBaseView)
	{
		return 0.0f;
	}
	
	CGPoint center = [self _centerPanelClosedPosition];
	
	if (_centerBaseView.center.x <= center.x)
	{
		return 0.0f;
	}
	
	CGRect leftCoveredArea = CGRectIntersection(_centerBaseView.frame, _leftBaseView.frame);
	return _leftBaseView.bounds.size.width - leftCoveredArea.size.width;
}

- (CGFloat)_rightPanelVisibleWidth
{
	if (!_rightBaseView)
	{
		return 0.0f;
	}
	
	CGPoint center = [self _centerPanelClosedPosition];
	
	if (_centerBaseView.center.x >= center.x)
	{
		return 0.0f;
	}
	
	CGRect rightCoveredArea = CGRectIntersection(_centerBaseView.frame, _rightBaseView.frame);
	return _rightBaseView.bounds.size.width - rightCoveredArea.size.width;
}

- (CGFloat)_minCenterPanelPosition
{
	CGFloat minCenterX = (self.view.bounds.size.width/2.0f);
	
	if (_rightPanelController)
	{
		minCenterX -= _centerBaseView.bounds.size.width;
		minCenterX += _minimumVisibleCenterWidth;
	}
	
	return minCenterX;
}

- (CGFloat)_maxCenterPanelPosition
{
	CGFloat maxCenterX = (self.view.bounds.size.width/2.0f);
	
	if (_leftPanelController)
	{
		maxCenterX += _centerBaseView.bounds.size.width;
		maxCenterX -= _minimumVisibleCenterWidth;
	}
	
	return maxCenterX;
}

- (CGPoint)_centerPanelPositionWithLeftPanelOpen
{
	return CGPointMake([self _maxCenterPanelPosition], _centerBaseView.center.y);
}

- (CGPoint)_centerPanelPositionWithRightPanelOpen
{
	return CGPointMake([self _minCenterPanelPosition], _centerBaseView.center.y);
}

- (CGPoint)_centerPanelClosedPosition
{
	return CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height/2.0f);
}

#pragma mark - Animations

- (void)_animateCenterPanelToPosition:(CGPoint)position withMomentum:(CGPoint)momentum
{
	CALayer *presentationlayer = _centerBaseView.layer.presentationLayer;
	CGPoint currentPosition = presentationlayer.position;
	
	CGFloat deltaX = position.x - currentPosition.x;
	CGFloat deltaY = position.y - currentPosition.y;

	CGFloat distanceToTravel = sqrtf(deltaX*deltaX + deltaY*deltaY);
	CGFloat distanceMomentum = sqrtf(momentum.x * momentum.x + momentum.y * momentum.y);
	
	// limit
	distanceMomentum = MIN(MAX(distanceMomentum, _minimumAnimationMomentum), _maximumAnimationMomentum);
	
	CGFloat durationForAnimation = distanceToTravel / distanceMomentum;
	
	[UIView animateWithDuration:durationForAnimation delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
		_centerBaseView.center = position;
	} completion:NULL];
}

- (void)_animateCenterPanelToClosedPosition
{
	[self _animateCenterPanelToPosition:[self _centerPanelClosedPosition] withMomentum:CGPointZero];
}

- (void)_animateLeftPanelToOpenPosition
{
	[self _animateCenterPanelToPosition:[self _centerPanelPositionWithLeftPanelOpen] withMomentum:CGPointZero];
}

- (void)_animateRightPanelToOpenPosition
{
	[self _animateCenterPanelToPosition:[self _centerPanelPositionWithRightPanelOpen] withMomentum:CGPointZero];
}

- (void)_animateCenterPanelToRestingPosition
{
	CGFloat leftVisibleWidth = [self _leftPanelVisibleWidth];
	CGFloat rightVisibleWidth = [self _rightPanelVisibleWidth];
	
	if (leftVisibleWidth>0)
	{
		if (leftVisibleWidth<_leftBaseView.bounds.size.width/2.0f)
		{
			[self _animateCenterPanelToClosedPosition];
		}
		else
		{
			[self _animateLeftPanelToOpenPosition];
		}
		
		return;
	}
	
	if (rightVisibleWidth>0)
	{
		if (rightVisibleWidth<_rightBaseView.bounds.size.width/2.0f)
		{
			[self _animateCenterPanelToClosedPosition];
		}
		else
		{
			[self _animateRightPanelToOpenPosition];
		}
	}
}

- (void)_animateCenterPanelToRestingPositionWithMomentum:(CGPoint)momentum
{
	CGFloat leftVisibleWidth = [self _leftPanelVisibleWidth];
	
	if (leftVisibleWidth>0)
	{
		if (momentum.x>0)
		{
			[self _animateCenterPanelToPosition:[self _centerPanelPositionWithLeftPanelOpen] withMomentum:momentum];
		}
		else
		{
			[self _animateCenterPanelToPosition:[self _centerPanelClosedPosition] withMomentum:momentum];
		}
		
		return;
	}
	
	CGFloat rightVisibleWidth = [self _rightPanelVisibleWidth];
	
	if (rightVisibleWidth>0)
	{
		if (momentum.x<0)
		{
			[self _animateCenterPanelToPosition:[self _centerPanelPositionWithRightPanelOpen] withMomentum:momentum];
		}
		else
		{
			[self _animateCenterPanelToPosition:[self _centerPanelClosedPosition] withMomentum:momentum];
		}
		
		return;
	}
}

#pragma mark - Rotation

- (void)viewDidLayoutSubviews
{
	NSLog(@"did layout");
	[super viewDidLayoutSubviews];
	
	[self presentPanel:self.presentedPanel animated:NO];
}

#pragma mark - Actions

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
	switch (gesture.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			
			break;
		}
			
		case UIGestureRecognizerStateChanged:
		{
			_lastTranslation = [gesture translationInView:self.view];
			_lastMoveTimestamp = [NSDate timeIntervalSinceReferenceDate];

			CGPoint center = _centerBaseView.center;
			center.x += _lastTranslation.x;
			
			// restrict to valid region
			center.x = MAX(MIN([self _maxCenterPanelPosition], center.x), [self _minCenterPanelPosition]);
			
			[gesture setTranslation:CGPointZero inView:self.view];
			
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			
			_centerBaseView.center = center;
			
			[CATransaction commit];
			
			[self _sortPanels];
			
			break;
		}
			
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
		{
			NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
			NSTimeInterval secondsSinceLastMovement = timestamp - _lastMoveTimestamp;
			
			if (secondsSinceLastMovement<0.2f)
			{
				CGPoint momentum = CGPointMake(_lastTranslation.x/secondsSinceLastMovement, _lastTranslation.y/secondsSinceLastMovement);
				
				[self _animateCenterPanelToRestingPositionWithMomentum:momentum];
			}
			else
			{
				[self _animateCenterPanelToRestingPosition];
			}
			
			break;
		}
			
		default:
		{
			
		}
			break;
	}
}

#pragma mark - Public Interface

- (void)presentPanel:(DTSidePanelControllerPanel)panel animated:(BOOL)animated
{
	CGPoint targetPosition;

	switch (panel)
	{
		case DTSidePanelControllerPanelLeft:
		{
			NSAssert(_leftBaseView, @"Cannot present a left panel if none is configured");

			if (_rightBaseView)
			{
				[self.view sendSubviewToBack:_rightBaseView];
			}
			
			targetPosition = [self _centerPanelPositionWithLeftPanelOpen];
			break;
		}
			
		case DTSidePanelControllerPanelCenter:
		{
			NSAssert(_centerBaseView, @"Cannot present a center panel if none is configured");

			targetPosition = [self _centerPanelClosedPosition];
			break;
		}

		case DTSidePanelControllerPanelRight:
		{
			NSAssert(_rightBaseView, @"Cannot present a right panel if none is configured");
			
			if (_leftBaseView)
			{
				[self.view sendSubviewToBack:_leftBaseView];
			}
			
			targetPosition = [self _centerPanelPositionWithRightPanelOpen];
			break;
		}
	}
	
	if (animated)
	{
		// uses minimum momentum for animation
		[self _animateCenterPanelToPosition:targetPosition withMomentum:CGPointZero];
	}
	else
	{
		_centerBaseView.center = targetPosition;
	}
}

- (DTSidePanelControllerPanel)presentedPanel
{
	if ([self _leftPanelVisibleWidth]>0)
	{
		return DTSidePanelControllerPanelLeft;
	}
	
	if ([self _rightPanelVisibleWidth]>0)
	{
		return DTSidePanelControllerPanelLeft;
	}
	
	return DTSidePanelControllerPanelCenter;
}

#pragma mark - Properties

- (void)setCenterPanelController:(UIViewController *)centerPanelController
{
	if (centerPanelController == _centerPanelController)
	{
		return;
	}
	
	[_centerPanelController willMoveToParentViewController:nil];
	[_centerPanelController removeFromParentViewController];
	[_centerPanelController didMoveToParentViewController:nil];
	
	_centerPanelController = centerPanelController;
	
	if (!_centerBaseView)
	{
		_centerBaseView = [[UIView alloc] initWithFrame:self.view.bounds];
		_centerBaseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:_centerBaseView];
		
		_centerBaseView.layer.shadowColor = [UIColor blackColor].CGColor;
		_centerBaseView.layer.shadowRadius = 5.0;
		_centerBaseView.layer.masksToBounds = NO;
		_centerBaseView.layer.shadowOffset = CGSizeMake(0, 0);
		_centerBaseView.layer.shadowOpacity = 0.5;
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		[_centerBaseView addGestureRecognizer:panGesture];
	}
	
	[self _sortPanels];
	
	[self addChildViewController:_centerPanelController];
	
	centerPanelController.view.frame = _centerBaseView.bounds;
	[_centerBaseView addSubview:_centerPanelController.view];
	
	[centerPanelController didMoveToParentViewController:self];
}

- (void)setLeftPanelController:(UIViewController *)leftPanelController
{
	if (leftPanelController == _leftPanelController)
	{
		return;
	}
	
	[_leftPanelController willMoveToParentViewController:nil];
	[_leftPanelController removeFromParentViewController];
	[_leftPanelController didMoveToParentViewController:nil];
	
	_leftPanelController = leftPanelController;
	
	if (!_leftBaseView)
	{
		CGRect frame = self.view.bounds;
		frame.size.width -= _minimumVisibleCenterWidth;
		
		_leftBaseView = [[UIView alloc] initWithFrame:frame];
		_leftBaseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:_leftBaseView];
	}
	
	[self _sortPanels];
	
	[self addChildViewController:_leftPanelController];
	
	_leftPanelController.view.frame = _leftBaseView.bounds;
	[_leftBaseView addSubview:_leftPanelController.view];
	
	[_leftPanelController didMoveToParentViewController:self];
}

- (void)setRightPanelController:(UIViewController *)rightPanelController
{
	if (rightPanelController == _rightPanelController)
	{
		return;
	}
	
	[_rightPanelController willMoveToParentViewController:nil];
	[_rightPanelController removeFromParentViewController];
	[_rightPanelController didMoveToParentViewController:nil];
	
	_rightPanelController = rightPanelController;
	
	if (!_rightBaseView)
	{
		CGRect frame = self.view.bounds;
		frame.size.width -= _minimumVisibleCenterWidth;
		frame.origin.x += _minimumVisibleCenterWidth;
		
		_rightBaseView = [[UIView alloc] initWithFrame:frame];
		_rightBaseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:_rightBaseView];
	}
	
	[self _sortPanels];
	
	[self addChildViewController:_rightPanelController];
	
	_rightPanelController.view.frame = _rightBaseView.bounds;
	[_rightBaseView addSubview:_rightPanelController.view];
	
	[_rightPanelController didMoveToParentViewController:self];
}


@end
