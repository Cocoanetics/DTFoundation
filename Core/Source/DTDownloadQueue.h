//
//  DTDownloadQueue.h
//  DTFoundation
//
//  Created by René Pirringer on 1/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTDownload.h"

@class DTDownload;
@class DTDownloadItem;


/**
* This block is called when the download is finished.
*
* @param the downloadable item
* @param the data that was downloaded. In case of an error this is nil
* @param if an error occurs then the error object is set an the previous data parameter is nil
*/
typedef void (^DTDownloadQueueCompletionBlock)(DTDownloadItem *, NSError *);

/**
* This block is called when the download is started an data is received
*
* @param the downloadable item
* @param the downloaded bytes that were already downloaded
* @param the total size of the download
* @param the speed of the download
*/
typedef void (^DTDownloadQueueProgressBlock)(DTDownloadItem *, long long int, long long int, float);


/**
 A global queue for <DTDownload> instances.

 Note: all URL parameters may only be remote URLs e.g. http: or https.
 */
@interface DTDownloadQueue : NSObject


/**-------------------------------------------------------------------------------------
 @name Accessing the Shared Instance
 ---------------------------------------------------------------------------------------
 */

/**
 Access the shared cache.
 @returns the shared instance of the download queue.
 */
+ (DTDownloadQueue *)sharedInstance;

/**
 The number of parallel downloads that the queue can have
 */
@property (nonatomic, assign) NSInteger numberOfParallelDownloads;

/**
 Starts downloading a given download item.
 @param completion The completion block to execute after the download is finished, either with a file or error.
 @param progress The block of code to execute for each step in the download progress
 */
- (void)downloadItem:(DTDownloadItem *)downloadItem completion:(DTDownloadQueueCompletionBlock)completion progress:(DTDownloadQueueProgressBlock)progress;

/**
 Cancels a download item
 @param downloadItem The download item to cancel
 */
- (void)cancelDownloadItem:(DTDownloadItem *)downloadItem;

@end