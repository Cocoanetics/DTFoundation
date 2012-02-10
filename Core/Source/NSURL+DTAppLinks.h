//
//  NSURL+DTAppLinks.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/25/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//


/** A collection of category extensions for `NSURL` that provide direct access to built-in app capabilites. 
 
 For example: Open the app store on the page for the app
 
	NSURL *appURL = [NSURL appStoreURLforApplicationIdentifier:@"463623298"];
	[[UIApplication sharedApplication] openURL:appURL];
 */

@interface NSURL (DTAppLinks)

/**-------------------------------------------------------------------------------------
 @name Mobile App Store Pages 
 ---------------------------------------------------------------------------------------
 */

/** Returns the URL to open the mobile app store on the app's page.
 
 @param identifier The application identifier that gets assigned to a new app when you add it to iTunes Connect.
 @return Returns the URL to the direct app store link
 */
+ (NSURL *)appStoreURLforApplicationIdentifier:(NSString *)identifier;


/** Returns the URL to open the mobile app store on the app's review page.
 
 The reviews page is a sub-page of the normal app landing page you get with appStoreURLforApplicationIdentifier:

 @param identifier The application identifier that gets assigned to a new app when you add it to iTunes Connect.
 @return Returns the URL to the direct app store link
 */
+ (NSURL *)appStoreReviewURLForApplicationIdentifier:(NSString *)identifier;

@end

