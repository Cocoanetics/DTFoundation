//
//  DTBlockFunctions.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 02.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Block Utility Methods
 */

/**
 Performs a block synchronous if execution is currently on the main thread or dispatches it asynchronously if not
 @param block The block to execute
 */
void DTBlockPerformSyncIfOnMainThreadElseAsync(void (^block)(void));
