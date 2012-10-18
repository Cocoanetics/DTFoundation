//
// Created by rene on 12.09.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DTActivityTitleView.h"


@interface DTActivityTitleView ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *titleLabel;


@end

@implementation DTActivityTitleView
{
    
}
@synthesize activityIndicator = _activityIndicator;


- (id)init
{
	self = [super init];
	if (self)
    {
        
		self.titleLabel = [[UILabel alloc] init];
		self.activityIndicator.hidesWhenStopped = YES;
		self.titleLabel.backgroundColor = [UIColor clearColor];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
			self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			self.titleLabel.textColor = [UIColor colorWithRed:113.0/255.0 green:120.0/255.0 blue:128.0/255.0 alpha:1.0];
			self.titleLabel.shadowOffset = CGSizeMake(0, 1);
			self.titleLabel.shadowColor = [UIColor whiteColor];
		}
        else
        {
			self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
			self.titleLabel.textColor = [UIColor whiteColor];
			self.titleLabel.shadowOffset = CGSizeMake(0, -1);
			self.titleLabel.shadowColor = [UIColor blackColor];
		}
		self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
		[self addSubview:self.titleLabel];
		[self addSubview:self.activityIndicator];
        
        
        //self.titleLabel.text
        
		[self calculateSize];
	}
	return self;
}

- (void)setTitle:(NSString *)title
{
	self.titleLabel.text = title;
	[self calculateSize];
}

- (NSString *)title
{
	return self.titleLabel.text;
}


- (void)calculateSize
{
	CGFloat gap = 5.0;
	CGFloat height = self.activityIndicator.frame.size.height;
	CGSize neededSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font];
	if (height < neededSize.height)
    {
		height = neededSize.height;
	}
	CGRect titleRect = CGRectMake(self.activityIndicator.frame.size.width+gap, 0, neededSize.width, height);
	self.titleLabel.frame = titleRect;
	self.frame = CGRectMake(0, 0, self.activityIndicator.frame.size.width+neededSize.width+gap, height);
}



- (void)setBusy:(BOOL)busy
{
	if (busy)
    {
		[self.activityIndicator startAnimating];
	} else {
		[self.activityIndicator stopAnimating];
	}
}

- (BOOL)busy
{
	return self.activityIndicator.isAnimating;
}


@end