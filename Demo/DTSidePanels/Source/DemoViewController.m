//
//  DemoViewController.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DemoViewController.h"
#import "DTActivityTitleView.h"

@implementation DemoViewController
{
	DTActivityTitleView *_activityTitleView;
}

#pragma mark - Appearance Notifications


- (void)viewDidLoad {
	//_activityTitleView = [[DTActivityTitleView alloc] initWithTitle:@"A very very very very very very very very long title"];

	_activityTitleView = [[DTActivityTitleView alloc] initWithTitle:@"Test Test Test Test Test Test Test"];
	[_activityTitleView setTitleFont:[UIFont systemFontOfSize:15.0f]];
	self.navigationItem.titleView = _activityTitleView;

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
	[super willMoveToParentViewController:parent];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
	[super didMoveToParentViewController:parent];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}


- (IBAction)busySwitchPressed:(id)sender {
	if ([sender isKindOfClass:[UISwitch class]]) {
		UISwitch *busySwitch = (UISwitch *)sender;
		_activityTitleView.busy = busySwitch.on;

	}
}

- (IBAction)marginSliderValueChanged:(id)sender {
	if ([sender isKindOfClass:[UISlider class]]) {
		UISlider *slider = (UISlider *)sender;
		[_activityTitleView setMargin:slider.value];

	}


}
@end
