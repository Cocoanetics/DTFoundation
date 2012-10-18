//
// Main aggregate header for 'DTFoundation'
//

// Global System Headers
// this prevents problems if you include DTFoundation.h in your PCH file but are missing these other system frameworks
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
	#import <MobileCoreServices/MobileCoreServices.h>
#else
	#import <AppKit/AppKit.h>
	#import <Cocoa/Cocoa.h>
#endif

// Constants
#import "DTFoundationConstants.h"

// Classes
#import "DTASN1Parser.h"
#import "DTAsyncFileDeleter.h"
#import "DTDownload.h"
#import "DTExtendedFileAttributes.h"
#import "DTHTMLParser.h"
#import "DTPDFDocument.h"
#import "DTVersion.h"
#import "DTZipArchive.h"

#if TARGET_OS_IPHONE
	#import "DTPieProgressIndicator.h"
	#import "DTActionSheet.h"
#endif

// Categories
#import "NSArray+DTError.h"
#import "NSData+Base64.h"
#import "NSData+DTCrypto.h"
#import "NSDictionary+DTError.h"
#import "NSMutableArray+DTMoving.h"
#import "NSObject+DTRuntime.h"
#import "NSString+DTFormatNumbers.h"
#import "NSString+DTPaths.h"
#import "NSString+DTURLEncoding.h"
#import "NSString+DTUTI.h"
#import "NSURL+DTAppLinks.h"
#import "NSURL+DTUnshorten.h"

#if TARGET_OS_IPHONE
	#import "UIApplication+DTNetworkActivity.h"
	#import "UIImage+DTFoundation.h"
	#import "UIView+DTFoundation.h"
	#import "UIWebView+DTFoundation.h"
	#import "UIView+DTActionHandlers.h"
#else
	#import "NSImage+DTUtilities.h"
	#import "NSDocument+DTFoundation.h"
	#import "NSWindowController+DTPanelControllerPresenting.h"
#endif

// Utility Functions
#import "DTUtils.h"