//
//  NSDocument+DTFoundation.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/1/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

/**
 Utility Methods for working with `NSDocument` instances.
 */

@interface NSDocument (DTFoundation)

/**
 Finds the current window controller showing the main document
 
 At present this always returns the window controller at index 0.
 @returns mainDocumentWindowController The main document window controller
 */
- (NSWindowController *)mainDocumentWindowController;

@end

#endif
