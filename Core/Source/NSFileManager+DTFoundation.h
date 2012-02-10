//
//  NSFileManager+DTFoundation.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/** This category adds several useful file operations for NSFileManager.
 */

@interface NSFileManager (DTFoundation)

/**-------------------------------------------------------------------------------------
 @name Asynchronous Operations
 ---------------------------------------------------------------------------------------
 */

/** Removes the file or directory at the specified path and immediately returns.
 
 This method moves the given item to a temporary name which is an instant operation. It then schedules an asynchronous background operation to actually remove the item.
 
 @param path A path string indicating the file or directory to remove. If the path specifies a directory, the contents of that directory are recursively removed. 
 */
- (void)removeItemAsynchronousAtPath:(NSString *)path;


/** Removes the file or directory at the specified URL.
 
 This method moves the given item to a temporary name which is an instant operation. It then schedules an asynchronous background operation to actually remove the item.
 
 @param URL A file URL specifying the file or directory to remove. If the URL specifies a directory, the contents of that directory are recursively removed.
 */
- (void)removeItemAsynchronousAtURL:(NSURL *)URL;



@end
