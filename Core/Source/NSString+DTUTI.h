//
// Created by rene on 01.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface NSString (DTUTI)


/**-------------------------------------------------------------------------------------
 @name Working with UTIs
 ---------------------------------------------------------------------------------------
 */

/**
* Method to get the MIME-Type for the given file extension. If no MIME-Type can be determined then 'application/octet-stream' is returned.
*
* @param extension the file extension
*
* @return the recommended MIME-Type for the given path extension.
*/
- (NSString *)MIMETypeForFileExtension:(NSString *)extension;

@end