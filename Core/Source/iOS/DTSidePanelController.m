//
//  DTSidePanelController.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTSidePanelController.h"
#import "UIView+DTFoundation.h"

#import <QuartzCore/QuartzCore.h>

@interface DTSidePanelController ()

@end

@implementation DTSidePanelController
{
	UIView *_centerBaseView;
	UIView *_leftBaseView;
	UIView *_rightBaseView;
	
	CGFloat _leftPanelWidth;
	CGFloat _rightPanelWidth;
	
	CGFloat _minimumVisibleCenterWidth;
	CGPoint _lastTranslation;
	
	NSTimeInterval _lastMoveTimestamp;
	CGFloat _minimumAnimationMomentum;
	CGFloat _maximumAnimationMomentum;
	
	DTSidePanelControllerPanel _panelToPresentAfterLayout;  // the panel presentation to restore after subview layouting
	BOOL _panelIsMoving;  // if the panel is being dragged or being animated
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

- (void)_updatePanelAutoresizingMasks
{
	if (_leftPanelWidth)
	{
		_leftBaseView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
	}
	else
	{
		_leftBaseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	
	if (_rightPanelWidth)
	{
		_rightBaseView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
	}
	else
	{
		_rightBaseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
		minCenterX -= [self _usedRightPanelWidth];
	}
	
	return minCenterX;
}

- (CGFloat)_maxCenterPanelPosition
{
	CGFloat maxCenterX = (self.view.bounds.size.width/2.0f);
	
	if (_leftPanelController)
	{
		maxCenterX += [self _usedLeftPanelWidth];
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

- (CGFloat)_usedLeftPanelWidth
{
	CGFloat usedWidth = _leftPanelWidth;
	CGFloat maxWidth = self.view.bounds.size.width - _minimumVisibleCenterWidth;
	
	if (usedWidth==0)
	{
		usedWidth = maxWidth;
	}
	else
	{
		usedWidth = MIN(maxWidth, usedWidth);
	}
	
	return usedWidth;
}

- (CGRect)_leftPanelFrame
{
	return CGRectMake(0, 0, [self _usedLeftPanelWidth], self.view.bounds.size.height);
}

- (CGFloat)_usedRightPanelWidth
{
	CGFloat usedWidth = _rightPanelWidth;
	CGFloat maxWidth = self.view.bounds.size.width - _minimumVisibleCenterWidth;
	
	if (usedWidth==0)
	{
		usedWidth = maxWidth;
	}
	else
	{
		usedWidth = MIN(maxWidth, usedWidth);
	}
	
	return usedWidth;
}

- (CGRect)_rightPanelFrame
{
	CGFloat usedWidth = [self _usedRightPanelWidth];

	return CGRectMake(self.view.bounds.size.width - usedWidth, 0, usedWidth, self.view.bounds.size.height);
}

#pragma mark - Animations

- (void)_animateCenterPanelToPosition:(CGPoint)position duration:(NSTimeInterval)duration
{
	_panelIsMoving = YES;
	
	[UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
		_centerBaseView.center = position;
	} completion:^(BOOL finished) {
		_panelIsMoving = NO;
	}];
}


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
	
	CGFloat duration = distanceToTravel / distanceMomentum;
	
	[self _animateCenterPanelToPosition:position duration:duration];
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

- (void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	
	if (!_panelIsMoving)
	{
		_panelToPresentAfterLayout = self.presentedPanel;
	}
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	if (!_panelIsMoving)
	{
		[self presentPanel:_panelToPresentAfterLayout animated:NO];
	}
	
	[_centerBaseView updateShadowPathToBounds:_centerBaseView.bounds withDuration:0.3];
}

#pragma mark - Actions

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
	switch (gesture.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			_panelIsMoving = YES;
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
			_panelIsMoving = NO;
			
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
	
	_panelToPresentAfterLayout = panel;

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
		[self _animateCenterPanelToPosition:targetPosition duration:0.25];
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
		return DTSidePanelControllerPanelRight;
	}
	
	return DTSidePanelControllerPanelCenter;
}

- (void)setWidth:(CGFloat)width forPanel:(DTSidePanelControllerPanel)panel animated:(BOOL)animated
{
	NSParameterAssert(panel != DTSidePanelControllerPanelCenter);
	
	switch (panel)
	{
		case DTSidePanelControllerPanelLeft:
		{
			_leftPanelWidth = width;
			break;
		}
			
		case DTSidePanelControllerPanelRight:
		{
			_rightPanelWidth = width;
			break;
		}
			
		case DTSidePanelControllerPanelCenter:
		{
			NSLog(@"Setting width for center panel not supported");
			break;
		}
	}
	
	CGFloat duration = animated?0.3:0;
	
	[UIView animateWithDuration:duration animations:^{
		_leftBaseView.frame = [self _leftPanelFrame];
		_rightBaseView.frame = [self _rightPanelFrame];
	}];
	
	[self _updatePanelAutoresizingMasks];
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
		
		[_centerBaseView addShadowWithColor:[UIColor blackColor] alpha:1 radius:6 offset:CGSizeZero];
		
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
		_leftBaseView = [[UIView alloc] initWithFrame:[self _leftPanelFrame]];
		[self.view addSubview:_leftBaseView];
	}
	
	[self _updatePanelAutoresizingMasks];
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
		_rightBaseView = [[UIView alloc] initWithFrame:[self _rightPanelFrame]];
		[self.view addSubview:_rightBaseView];
	}
	
	[self _updatePanelAutoresizingMasks];
	[self _sortPanels];
	
	[self addChildViewController:_rightPanelController];
	
	_rightPanelController.view.frame = _rightBaseView.bounds;
	[_rightBaseView addSubview:_rightPanelController.view];
	
	[_rightPanelController didMoveToParentViewController:self];
}


@end
