//
//  ViewController.m
//  PDFDemo
//
//  Created by Stefan Gugarel on 9/24/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "ViewController.h"
#import "DTPDFViewController.h"
#import "DTPDFDocument.h"
#import "DTPDFPage.h"

@interface ViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@end

@implementation ViewController 
{
    NSArray *_pageViewControllers;
    UIPageViewController *_pageViewController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Bloomingdales-ShoeandHandbag-2012" ofType:@"pdf"];
    
    NSURL *pdfURL = [NSURL fileURLWithPath:filePath];
    
    DTPDFDocument *document = [[DTPDFDocument alloc] initWithURL:pdfURL];
    
    NSMutableArray *pdfViewControllers = [NSMutableArray array];
    
    for (DTPDFPage *pdfPage in document.pages)
    {
        DTPDFViewController *pdfViewController = [[DTPDFViewController alloc] initWithPDFPage:pdfPage];
        
        [pdfViewControllers addObject:pdfViewController];
    }
    
    _pageViewControllers = pdfViewControllers;

    
    
	// Do any additional setup after loading the view, typically from a nib.
    // Configure the page view controller and add it as a child view controller.
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.delegate = self;
    
    NSArray *initialPages = [NSArray arrayWithObjects:[_pageViewControllers objectAtIndex:0], nil];
    
    [_pageViewController setViewControllers:initialPages direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    
    _pageViewController.dataSource = self;
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    
    // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
    CGRect pageViewRect = self.view.bounds;
    _pageViewController.view.frame = pageViewRect;
    
    [_pageViewController didMoveToParentViewController:self];
    
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = _pageViewController.gestureRecognizers;
}
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//	// Do any additional setup after loading the view, typically from a nib.
//    
//    
//    //self.spineLocation = UIPageViewControllerSpineLocationNone;
//    
////    NSDictionary *options =
////    [NSDictionary dictionaryWithObject:
////    [NSNumber numberWithInteger:UIPageViewControllerSpineLocationMin]
////                                forKey: UIPageViewControllerOptionSpineLocationKey];
//    
//    //NSArray *viewControllers = [NSArray arrayWithObject:[pdfViewControllers objectAtIndex:0]];
//    
//    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
//    
//    NSArray *initialPages = [NSArray arrayWithObjects:[_pageViewControllers objectAtIndex:0], nil];
//    
//    [_pageViewController setViewControllers:initialPages direction:UIPageViewControllerNavigationDirectionForward animated:TRUE completion:^(BOOL finished) {
//        NSLog(@"fertig!!");
//    }];
//
//    
//    _pageViewController.dataSource = self;
//    _pageViewController.delegate = self;
//    
//    _pageViewController.view.frame = self.view.bounds;
//    [self.view addSubview:_pageViewController.view];
//    
//    [self addChildViewController:_pageViewController];
//}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UIPageViewController

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger pageIndex = [_pageViewControllers indexOfObject:viewController];
    
    if (pageIndex>0)
    {
        return [_pageViewControllers objectAtIndex:pageIndex-1];
    }
    
    return nil;
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger pageIndex = [_pageViewControllers indexOfObject:viewController];
    
    if (pageIndex<[_pageViewControllers count]-1)
    {
        return [_pageViewControllers objectAtIndex:pageIndex+1];
    }
    
    return nil;
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    NSMutableArray *viewControllersToShow = [NSMutableArray array];

    UIViewController *currentViewController = pageViewController.viewControllers[0];
    [viewControllersToShow addObject:currentViewController];
    
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
    // Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES, so set it to NO here.
        
        [pageViewController setViewControllers:viewControllersToShow direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
            for (UIViewController *vc in viewControllersToShow)
            {
                vc.view.alpha = 1;
              //  [vc didMoveToParentViewController:pageViewController];

            }
        }];
    
    pageViewController.doubleSided = NO;
    return UIPageViewControllerSpineLocationMin;
    }
    
    // we also need a second
    NSUInteger pageIndex = [_pageViewControllers indexOfObject:currentViewController];
    
    if (pageIndex<[_pageViewControllers count]-1)
    {
        [viewControllersToShow addObject:[_pageViewControllers objectAtIndex:pageIndex+1]];
    }
    else
    {
        [viewControllersToShow addObject:[_pageViewControllers objectAtIndex:pageIndex-1]];
    }
    
    [pageViewController setViewControllers:viewControllersToShow direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
        for (UIViewController *vc in viewControllersToShow)
        {
            vc.view.alpha = 1;
            //[vc didMoveToParentViewController:pageViewController];
        }
    }];
    
    pageViewController.doubleSided = NO;
    return UIPageViewControllerSpineLocationMid;
}



@end
