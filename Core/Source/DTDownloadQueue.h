//
// Created by rene on 20.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
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


@property (nonatomic, assign) NSInteger numberOfParallelDownloads;


- (void)downloadItem:(DTDownloadItem *)downloadItem completion:(DTDownloadQueueCompletionBlock)completion progress:(DTDownloadQueueProgressBlock)progress;
- (void)cancelDownloadItem:(DTDownloadItem *)downloadItem;


@end