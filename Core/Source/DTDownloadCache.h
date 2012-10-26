//
//  DTDownloadCache.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/20/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTDownload.h"

extern NSString *DTDownloadCacheDidCacheFileNotification;


enum {
    DTDownloadCacheOptionNeverLoad = 0,
    DTDownloadCacheOptionLoadIfNotCached,
    DTDownloadCacheOptionReturnCacheAndLoadAlways,
    DTDownloadCacheOptionReturnCacheAndLoadIfChanged,
};
typedef NSUInteger DTDownloadCacheOption;


typedef void (^DTDownloadCacheDataCompletionBlock)(NSURL *, NSData *);
typedef void (^DTDownloadCacheImageCompletionBlock)(NSURL *, UIImage *);

/**
 A global cache for <DTDownload> instances
 */

@interface DTDownloadCache : NSObject <DTDownloadDelegate>

/**
 Access the shared cache.
 @returns the shared instance of the download cache.
 */
+ (DTDownloadCache *)sharedInstance;

/**
 @param URL The URL of the file
 @param option A loading option to specify wheter the file should be loaded if it is already cached.
 @returns The cached image or `nil` if none is cached.
 */
- (NSData *)cachedDataForURL:(NSURL *)URL option:(DTDownloadCacheOption)option;

/**
 current sum of cached files in Bytes
 */
- (NSUInteger)currentDiskUsage;

/**
 The number of downloads that can go on at the same time.
 */
@property (nonatomic, assign) NSUInteger maxNumberOfConcurrentDownloads;

/**
 The maximum disk space used for caching files. The default value is 20 MB.
 */
@property (nonatomic, assign) NSUInteger diskCapacity;

@end


/**
 Specialized methods for dealing with images. An NSCache holds on to UIImage references after they have been retrieved once since that speeds up subsequent drawing.
 */
@interface DTDownloadCache (Images)


/**
 Specialized method for retrieving cached images.
 @param URL The URL of the image
 @param option A loading option to specify wheter the file should be loaded if it is already cached.
 @returns The cached image or `nil` if none is cached.
 */
- (UIImage *)cachedImageForURL:(NSURL *)URL option:(DTDownloadCacheOption)option;


/**
 Provides the cached or downloaded image.
 
 If the image is already cached it will be returned and the block not be executed. If it needs to be loaded then `nil` is returned and the block gets executed as soon as the image has been downloaded.
 @param URL The URL of the image
 @param option A loading option to specify wheter the file should be loaded if it is already cached.
 @param completion The block to be executed when the image is available.
 @returns The cached image or `nil` if none is cached.
 */
- (UIImage *)cachedImageForURL:(NSURL *)URL option:(DTDownloadCacheOption)option completion:(DTDownloadCacheImageCompletionBlock)completion;

@end
