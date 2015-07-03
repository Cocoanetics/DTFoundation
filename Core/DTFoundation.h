//
// Main aggregate header for 'DTFoundation'
//

// Global System Headers
// this prevents problems if you include DTFoundation.h in your PCH file but are missing these other system frameworks

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#else
	#import <AppKit/AppKit.h>
	#import <Cocoa/Cocoa.h>
#endif


#pragma mark - Universal

// Constants
#import "DTFoundationConstants.h"

// Functions
#import "DTBlockFunctions.h"

// Headers
#import "DTWeakSupport.h"

// Categories
#import "NSArray+DTError.h"
#import "NSData+DTCrypto.h"
#import "NSDictionary+DTError.h"
#import "NSFileWrapper+DTCopying.h"
#import "NSMutableArray+DTMoving.h"
#import "NSString+DTFormatNumbers.h"
#import "NSString+DTUtilities.h"
#import "NSString+DTPaths.h"
#import "NSString+DTURLEncoding.h"
#import "NSURL+DTComparing.h"
#import "NSURL+DTUnshorten.h"

// Core Graphics
#import "DTCoreGraphicsUtils.h"

// Runtime
#import "DTObjectBlockExecutor.h"
#import "NSObject+DTRuntime.h"

// Classes
#import "DTAsyncFileDeleter.h"
#import "DTBase64Coding.h"
#import "DTExtendedFileAttributes.h"
#import "DTFolderMonitor.h"
#import "DTLog.h"
#import "DTVersion.h"

#import "DTHTMLParser.h"


#pragma mark - iOS

#if TARGET_OS_IPHONE

// BlocksAdditions
#import "DTActionSheet.h"
#import "DTAlertView.h"
#import "UIView+DTActionHandlers.h"

// Debug
#import "UIColor+DTDebug.h"
#import "UIView+DTDebug.h"

// DTSidePanel
#import "DTSidePanelController.h"
#import "UIViewController+DTSidePanelController.h"
#import "DTSidePanelPanGestureRecognizer.h"
#import "DTSidePanelControllerSegue.h"

// Misc
#import "DTTiledLayerWithoutFade.h"
#import "DTActivityTitleView.h"
#import "DTCustomColoredAccessory.h"
#import "DTPieProgressIndicator.h"
#import "DTSmartPagingScrollView.h"
#import "UIApplication+DTNetworkActivity.h"
#import "UIImage+DTFoundation.h"
#import "NSURL+DTAppLinks.h"
#import "UIView+DTFoundation.h"
#import "UIWebView+DTFoundation.h"

#import "DTAnimatedGIF.h"

#endif


#pragma mark - OSX

#if !TARGET_OS_IPHONE

#import "DTScrollView.h"
#import "NSDocument+DTFoundation.h"
#import "NSImage+DTUtilities.h"
#import "NSValue+DTConversion.h"
#import "NSView+DTAutoLayout.h"
#import "NSWindowController+DTPanelControllerPresenting.h"

#endif
