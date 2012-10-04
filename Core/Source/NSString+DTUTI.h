//
//  NSString+DTUTI.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Utility methods that work with Universal Type Identifiers (UTI).
 */

@interface NSString (DTUTI)


/**-------------------------------------------------------------------------------------
 @name Working with UTIs
 ---------------------------------------------------------------------------------------
 */

/**
 Method to get the recommended MIME-Type for the given file extension. If no MIME-Type can be determined then 'application/octet-stream' is returned.
 @param extension the file extension
 @return the recommended MIME-Type for the given path extension.
*/
+ (NSString *)MIMETypeForFileExtension:(NSString *)extension;

@end